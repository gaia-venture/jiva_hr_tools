require "graphql/client"
require "graphql/client/http"

# Star Wars API example wrapper
module JivaHrTools::FreshteamGraphql
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new(ENV["FRESHGRAPHQL_ENDPOINT"]) do
    def headers(context)
      # Optionally set any HTTP headers
      { "Authorization": "Bearer #{ENV["FRESHGRAPHQL_TOKEN"]}" }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  EmployeesOnLeave = Client.parse <<-EOGQL
  query($startDate: Date!) {
    leaves(startDate: $startDate) {
      startDate
      endDate
      employee {
        firstName
        lastName
        pod {
          name
          slackChannel
        }
      }
    }
  }
EOGQL
end