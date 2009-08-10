# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  

    def navigation(tabs)
      items = []
      tabs.each do |tab|
        if (controller.controller_name.to_sym.to_s == tab["link"])
          items << content_tag(:li, content_tag(:div, tab["title"]), :class => "selected")
          #items << tab.inspect
        else
          items << content_tag(:li, link_to("#{tab["title"].to_s}", tab["link"]))
        end
      end
      content_tag :ul, items, :id=>"tabs"
    end

  
end
