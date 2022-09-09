module JivaHrTools
  class PostToSlack
    def self.perform
      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true
      http.start { |http| yield new(http) }
    end

    private_class_method :new
    def initialize(http)
      @http = http
    end

    def post_leaves(slack_channel, leaves)
      return unless slack_channel.present?
      today = Time.now.strftime("%Y-%m-%d")

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
        channel: ENV["TESTING_JIVA_BOT"].present? ? "#testing-jiva-bot" : slack_channel,
        blocks: [{
          type: "section",
          text: {
            type: "mrkdwn",
            text: msg
          }
        }]
      })
      response = @http.request(request)
      p response.code
    end
  end
end