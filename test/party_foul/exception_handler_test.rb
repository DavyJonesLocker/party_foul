require 'test_helper'

describe 'Party Foul Exception Handler' do
  before do
    PartyFoul.configure do |config|
      config.oauth_token = 'abcdefg1234567890'
      config.owner       = 'test_owner'
      config.repo        = 'test_repo'
    end

    PartyFoul.stubs(:branch).returns('deploy')
    PartyFoul::IssueRenderers::Rails.any_instance.stubs(:title).returns('Test Title')
    PartyFoul::IssueRenderers::Rails.any_instance.stubs(:fingerprint).returns('test_fingerprint')
  end

  context 'when error is new' do
    it 'will open a new error on GitHub' do
      PartyFoul::IssueRenderers::Rails.any_instance.stubs(:body).returns('Test Body')
      PartyFoul::IssueRenderers::Rails.any_instance.stubs(:comment).returns('Test Comment')
      PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(no_search_results)
      PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:closed').returns(no_search_results)
      PartyFoul.github.expects(:create_issue).with('test_owner/test_repo', 'Test Title', 'Test Body', labels: ['bug']).returns( {number: 1} )
      PartyFoul.github.expects(:references).with('test_owner/test_repo', 'heads/deploy').returns( sawyer_resource({object: {sha: 'abcdefg1234567890'}}) )
      PartyFoul.github.expects(:add_comment).with('test_owner/test_repo', 1, 'Test Comment')
      PartyFoul::ExceptionHandler.new(nil, {}).run
    end

    context 'when additional labels are configured' do
      before do
        PartyFoul.configure do |config|
          config.additional_labels = ['custom', 'label']
        end
      end
      after do
        clean_up_party
      end
      it 'will open a new error on GitHub with the additional labels' do
        PartyFoul::IssueRenderers::Rails.any_instance.stubs(:body).returns('Test Body')
        PartyFoul::IssueRenderers::Rails.any_instance.stubs(:comment).returns('Test Comment')
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(no_search_results)
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:closed').returns(no_search_results)
        PartyFoul.github.expects(:create_issue).with('test_owner/test_repo', 'Test Title', 'Test Body', :labels => ['bug', 'custom', 'label']).returns( { number: 1 } )
        PartyFoul.github.expects(:references).with('test_owner/test_repo', 'heads/deploy').returns( sawyer_resource({object: {sha: 'abcdefg1234567890'}}) )
        PartyFoul.github.expects(:add_comment).with('test_owner/test_repo', 1, 'Test Comment')
        PartyFoul::ExceptionHandler.new(nil, {}).run
      end
    end

    context 'when a proc for additional labels are configured' do
      before do
        PartyFoul.configure do |config|
          config.additional_labels = Proc.new do |exception, env|
            if env[:http_host] =~ /beta\./
              ['beta']
            elsif exception.message =~ /Database/
              ['database_error']
            end
          end
        end
        PartyFoul::IssueRenderers::Rails.any_instance.stubs(:body).returns('Test Body')
        PartyFoul::IssueRenderers::Rails.any_instance.stubs(:comment).returns('Test Comment')
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(no_search_results)
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:closed').returns(no_search_results)
        PartyFoul.github.expects(:references).with('test_owner/test_repo', 'heads/deploy').returns( sawyer_resource({object: {sha: 'abcdefg1234567890'}}) )
        PartyFoul.github.expects(:add_comment).with('test_owner/test_repo', 1, 'Test Comment')
      end
      after do
        clean_up_party
      end

      it 'will open a new error on GitHub with the default labels if no additional labels are returned from the proc' do
        PartyFoul.github.expects(:create_issue).with('test_owner/test_repo', 'Test Title', 'Test Body', :labels => ['bug']).returns({ number: 1 })
        PartyFoul::ExceptionHandler.new(stub(:message => ''), {}).run
      end

      it 'will open a new error on GitHub with the additional labels based on the exception message' do
        PartyFoul.github.expects(:create_issue).with('test_owner/test_repo', 'Test Title', 'Test Body', :labels => ['bug', 'database_error']).returns({ number: 1 })
        PartyFoul::ExceptionHandler.new(stub(:message => 'Database'), {}).run
      end

      it 'will open a new error on GitHub with the additional labels based on the env' do
        PartyFoul.github.expects(:create_issue).with('test_owner/test_repo', 'Test Title', 'Test Body', :labels => ['bug', 'beta']).returns({ number: 1 })
        PartyFoul::ExceptionHandler.new(stub(:message => ''), {:http_host => 'beta.example.com'}).run
      end
    end
  end

  context 'when error is not new' do
    before do
      PartyFoul::IssueRenderers::Rails.any_instance.stubs(:update_body).returns('New Body')
      PartyFoul::IssueRenderers::Rails.any_instance.stubs(:comment).returns('Test Comment')
    end

    context 'and open' do
      before do
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(
          sawyer_resource({total_count: 1, incomplete_results: false, items:[{title: 'Test Title', body: 'Test Body', state: 'open', number: 1}]}) )
        PartyFoul.github.expects(:update_issue).with('test_owner/test_repo', 1, 'Test Title', 'New Body', state: 'open')
        PartyFoul.github.expects(:references).with('test_owner/test_repo', 'heads/deploy').returns(
          sawyer_resource({object: {sha: 'abcdefg1234567890'}}) )
      end

      it 'will update the issue' do
        PartyFoul.github.expects(:add_comment).with('test_owner/test_repo', 1, 'Test Comment')
        PartyFoul::ExceptionHandler.new(nil, {}).run
      end

      it "doesn't post a comment if the limit has been met" do
        PartyFoul.configure do |config|
          config.comment_limit = 10
        end
        PartyFoul::ExceptionHandler.any_instance.expects(:occurrence_count).returns(10)
        PartyFoul.github.expects(:add_comment).never
        PartyFoul::ExceptionHandler.new(nil, {}).run
      end
    end

    context 'and closed' do
      it 'will update the count on the body and re-open the issue' do
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(no_search_results)
        PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:closed').returns(
          sawyer_resource({total_count: 1, incomplete_results: false, items:[{title: 'Test Title', body: 'Test Body', state: 'closed', number: 1, labels: [{url: 'https://api.github.com/repos/test_owner/test_repo/labels/staging', name: 'staging', color: 'f29513'}]}]}) )
        PartyFoul.github.expects(:update_issue).with('test_owner/test_repo', 1, 'Test Title', 'New Body', state: 'open', labels: ['bug', 'regression', 'staging'])
        PartyFoul.github.expects(:add_comment).with('test_owner/test_repo', 1, 'Test Comment')
        PartyFoul.github.expects(:references).with('test_owner/test_repo', 'heads/deploy').returns(sawyer_resource({object: {sha: 'abcdefg1234567890'}}))
        PartyFoul::ExceptionHandler.new(nil, {}).run
      end
    end
  end

  context 'when issue is marked as "wontfix"' do
    it 'does nothing' do
      PartyFoul::IssueRenderers::Rails.any_instance.stubs(:body).returns('Test Body')
      PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:open').returns(no_search_results)
      PartyFoul.github.expects(:search_issues).with('test_fingerprint repo:test_owner/test_repo state:closed').returns(
        sawyer_resource({total_count: 1, incomplete_results: false, items:[{title: 'Test Title', body: 'Test Body', state: 'closed', number: 1, labels: [{url: 'https://api.github.com/repos/test_owner/test_repo/labels/wontfix', name: 'wontfix', color: 'f29513'}]}]}) )
      PartyFoul.github.expects(:create_issue).never
      PartyFoul.github.expects(:update_issue).never
      PartyFoul.github.expects(:add_comment).never
      PartyFoul.github.expects(:references).never
      PartyFoul::ExceptionHandler.new(nil, {}).run
    end
  end

  describe '#occurrence_count' do
    before do
      @handler = PartyFoul::ExceptionHandler.new(nil, {})
    end

    it "returns the count" do
      @handler.send(:occurrence_count, "<th>Count</th><td>1</td>").must_equal 1
    end

    it "returns 0 if no count is found" do
      @handler.send(:occurrence_count, "Unexpected Body").must_equal 0
    end
  end

  describe '#comment_limit_met?' do
    before do
      @handler = PartyFoul::ExceptionHandler.new(nil, {})
    end

    context "with no limit" do
      it "returns false when there is no limit" do
        PartyFoul.configure do |config|
          config.comment_limit = nil
        end
        @handler.send(:comment_limit_met?, "").must_equal false
      end
    end

    context "with a limit" do
      before do
        PartyFoul.configure do |config|
          config.comment_limit = 10
        end
      end

      it "returns false when there is a limit that has not been hit" do
        @handler.stubs(:occurrence_count).returns(1)
        @handler.send(:comment_limit_met?, "").must_equal false
      end

      it "returns true if the limit has been hit" do
        @handler.stubs(:occurrence_count).returns(10)
        @handler.send(:comment_limit_met?, "").must_equal true
      end
    end
  end

  describe '.clean_env' do
    context 'when env contains file reference' do
      before do
        @env = { 
          'action_dispatch.request.parameters' => {
            :@tempfile => File.open(__FILE__)
          }
        }
      end

      it "marshal dump shouldn't reject values when they contain File" do
        PartyFoul::ExceptionHandler.send(:clean_env, @env)['action_dispatch.request.parameters'].must_be_instance_of Hash
      end
    end
  end
end
