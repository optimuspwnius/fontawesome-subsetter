module FontawesomeSubsetter

  module IconHelper

    def icon(style, name, text = nil, html_options = {}, &block)
      text, html_options = nil, text if text.is_a?(Hash)

      html_options[:class] = "#{ style } fa-#{ name.to_s.dasherize }#{ " #{ html_options[:class] }" if html_options.key? :class }"

      html = content_tag :i, nil, html_options

      html = "#{ html } #{ text }" if text.present?

      html = "#{ html } #{ capture block }" if block_given?

      html.html_safe
    end

  end

end
