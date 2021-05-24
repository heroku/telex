require "erubis"
require "redcarpet"
require "redcarpet/render_strip"
require "mail"

class Telex::Emailer
  HTML_TEMPLATE = File.read(File.expand_path("../../templates/email.html.erb", __FILE__))

  class DeliveryError < StandardError; end

  def initialize(email:, subject:, body:, notification_id: nil, in_reply_to: nil, action: nil, from: nil, strip_text: false)
    self.email = email
    self.notification_id = notification_id
    self.in_reply_to = in_reply_to
    self.subject = subject
    self.body = body
    self.action = action
    self.from = from
    self.strip_text = strip_text
  end

  def deliver!
    mail = Mail.new
    mail.to = email
    mail.from = from || "Heroku Notifications <bot@notifications.heroku.com>"
    mail.subject = subject
    if notification_id
      mail.message_id = "<#{notification_id}@notifications.heroku.com>"
    elsif in_reply_to
      mail.in_reply_to = "<#{in_reply_to}@notifications.heroku.com>"
    end

    text_part = Mail::Part.new
    text_part.content_type = "text/plain; charset=UTF-8"
    text_part.body = body
    mail.text_part = strip_text ? generate_text : text_part

    html_part = Mail::Part.new
    html_part.content_type = "text/html; charset=UTF-8"
    html_part.body = generate_html
    mail.html_part = html_part

    mail.deliver!
    Telex::Sample.count "emails"
    mail
  rescue Timeout::Error, Errno::ECONNRESET, EOFError => e
    # Mail just 'splodes and sends everything up
    Telex::Sample.count "email_error"
    Pliny.log(
      email_error: true,
      error: e.class,
      to: email,
      from: from,
      notification_id: notification_id
    )
    raise DeliveryError.new(e.message)
  end

  private

  attr_accessor :email, :notification_id, :subject, :body, :in_reply_to, :action, :from, :strip_text

  def generate_text
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::StripDown.new
    )
    markdown.render(body)
  end

  def generate_html
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(filter_html: true),
      tables: true,
      no_intra_emphasis: true,
      autolink: true
    )
    rendered_body = markdown.render(body)

    Erubis::Eruby.new(HTML_TEMPLATE).result(
      body: rendered_body,
      png_url: png_url,
      email_action_ld: email_action_ld
    )
  end

  def png_url
    id = notification_id || in_reply_to
    return nil unless id

    if Config.deployment == "production"
      "https://telex.heroku.com/user/notifications/#{id}/read.png"
    elsif Config.deployment == "staging"
      "https://telex-staging.herokuapp.com/user/notifications/#{id}/read.png"
    end
  end

  def email_action_ld
    return unless action
    {
      "@context" => "http://schema.org",
      "@type" => "EmailMessage",
      "potentialAction" => {
        "@type" => "ViewAction",
        "target" => action[:url],
        "name" => action[:label]
      },
      "description" => action[:label]
    }
  end
end

# module Redcarpet
#   module Render
#     # Markdown-stripping renderer. Turns Markdown into plaintext
#     # Thanks to @toupeira (Markus Koller)
#     class StripDown < HTML
#       # Methods where the first argument is the text content
#       [
#         # block-level calls
#         :block_code, :block_quote,
#         :block_html, :list, :list_item,
#
#         # span-level calls
#         :autolink, :codespan, :double_emphasis,
#         :emphasis, :underline, :raw_html,
#         :triple_emphasis, :strikethrough,
#         :superscript, :highlight,
#
#         # footnotes
#         :footnotes, :footnote_def, :footnote_ref,
#
#         # low level rendering
#         :entity, :normal_text
#       ].each do |method|
#         define_method method do |*args|
#           args.first
#         end
#       end
#
#       # Other methods where we don't return only a specific argument
#       def link(link, title, content)
#         "#{content} (#{link})"
#       end
#
#       def image(link, title, content)
#         content &&= content + " "
#         "#{content}#{link}"
#       end
#
#       def paragraph(text)
#         text + "\\n"
#       end
#
#       def header(text, header_level)
#         text + "\\n"
#       end
#
#       def table(header, body)
#         "#{header}#{body}"
#       end
#
#       def table_row(content)
#         content + "\\n"
#       end
#
#       def table_cell(content, alignment)
#         content + "\\t"
#       end
#     end
#   end
# end
