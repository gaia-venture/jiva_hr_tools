require 'thor'

require "jiva_hr_tools"

module JivaHrTools
  class CLI < Thor
    desc "post_leaves_to_slack", "Post Leaves to slack"
    def post_leaves_to_slack
      result = JivaHrTools::FreshteamGraphql::Client.query(JivaHrTools::FreshteamGraphql::EmployeesOnLeave, variables: {
        startDate: Time.now.strftime("%Y-%m-%d")
      })
      if !result.errors.empty?
        puts "Got an Error: ", result.errors.first
        exit 1
      end
      leaves_by_pod = result.data.leaves.group_by { |leave| leave.employee&.pod&.slack_channel }
      PostToSlack.perform do |slack_client|
        slack_client.post_leaves("#annual-leave-notifications", result.data.leaves)
        leaves_by_pod.each { |slack_channel, leaves| slack_client.post_leaves(slack_channel, leaves) }
      end
    end
  end
end
