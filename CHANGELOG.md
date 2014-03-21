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
