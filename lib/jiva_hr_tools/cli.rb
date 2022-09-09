require 'thor'

require "jiva_hr_tools"

module JivaHrTools
  class CLI < Thor
    desc "post_leaves_to_slack", "Post Leaves to slack"
    def post_leaves_to_slack
      today = Time.now.strftime("%Y-%m-%d")
      result = JivaHrTools::FreshteamGraphql::Client.query(JivaHrTools::FreshteamGraphql::EmployeesOnLeave, variables: {
        startDate: today
      })
      if !result.errors.empty?
        puts "Got an Error: ", result.errors.first
        exit 1
      end
      leaves_by_pod = result.data.leaves.group_by { |leave| leave.employee&.pod&.slack_channel }
      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true
      http.start do |http|
        leaves_by_pod.each do |slack_channel, leaves|
          next unless slack_channel.present?
          msg = "People On Leave Today (#{slack_channel}):\n" +
            leaves
              .map do |leave|
                time_msg = leave.end_date == today ? "" : " (till #{Time.parse(leave.end_date).strftime("%a %d/%m")})"
                "- #{leave.employee.first_name} #{leave.employee.last_name}#{time_msg}"
              end
              .join("\n")
          request = Net::HTTP::Post.new("https://slack.com/api/chat.postMessage")
          request["Accept"] = "application/json"
          request["Content-Type"] = "application/json; charset=utf-8"
          request["Authorization"] = "Bearer #{ENV["SLACK_TOKEN"]}"
          request.body = JSON.generate({
            channel: "#testing-jiva-bot",
            blocks: [{
              type: "section",
              text: {
                type: "mrkdwn",
                text: msg
              }
            }]
          })
          response = http.request(request)
          p response.code
        end
      end
    end
  end
end
