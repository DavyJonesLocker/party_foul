## 1.5.7
  * Truncate GH issue title to 150 chars - anything longer now seems
    to cause a 422 error from GH.
## 1.5.6
 * Upgrade Octokit to 4.x

## 1.5.5
 * Remove unused attr whitelisted\_rack\_variables
 * env['action_dispatch.request.parameters'] not present when file is
   beeing uploaded

## 1.5.4
 * Fix test hanging
 * Updated to Octokit 3.1
 * Use proper search API

## 1.5.3
 * All issue searches are now performed against the v3 GitHub API rather than
   using the legacy API.

## 1.5.2
 * Changes the dependency on Octokit to pessimistic minor version, as
   opposed to pessimistic patch version - Rodrigo Pinto

## 1.5.1

 * Uses `env['action_dispatch.request.parameters']` instead of
   `path_parameters` in rails renderer to fix missing params issue
   ([Bug #82](https://github.com/dockyard/party_foul/issues/82)) - Dan McClain

## 1.5.0

 * Uses `Time.current` in `PartyFoul::IssueRenderer::Rails` to use the
   application time instead of server time
   ([Bug #73](https://github.com/dockyard/party_foul/issues/73)) - Dan McClain

 * Title prefixing - Javier Martin
 * Do not link to Heroku bundled gems - Brian Cardarella & Romina Vargas
