module OntologyMetricsHelper
  def format_metric_list(metrics, metric, title)
    return 0 if metric.nil?

    markup = ""

    # IF all of the classes triggered the metric, return the class count
    if metric.include?("alltriggered")
      markup = "#{metrics.numberOfClasses}"
    elsif metric.kind_of?(Array) && metric.length == 1 && metric[0].include?("limitpassed")
      # Split at the magic marker and return the count
      markup = metric[0].split(":")[1]
    elsif metric.kind_of?(Hash) && metric.length == 1 && metric["limitpassed:"]
      # Return the count, which is an int value to the key 'limitpassed:'
      markup = metric["limitpassed:"]
    elsif metric.kind_of?(Array) && metric.length == 0
      # If we have an empty array return 0
      markup = "0"
    elsif metric.kind_of?(Array)
      markup << "<a class='thickbox' href='#TB_inline?height=600&width=800&inlineId=#{metric.object_id}'>#{metric.length}</a>"
      markup << "<div id='#{metric.object_id}' style='display: none;'><div class='metrics'>"
      markup << "<h2>#{title}</h2><p>"
      markup << metric.join("<br/>")
      markup << "</p></div></div>"
    elsif metric.kind_of?(Hash)
      counts = []
      metric.each do |cls, count|
        counts << "#{cls} (#{count})"
      end

      metric = counts

      markup << "<a class='thickbox' href='#TB_inline?height=600&width=800&inlineId=#{metric.object_id}'>#{metric.length}</a>"
      markup << "<div id='#{metric.object_id}' style='display: none;'><div class='metrics'>"
      markup << "<h2>#{title}</h2><p>"
      markup << metric.join("<br/>")
      markup << "</p></div></div>"
    else
      markup = metric.to_s
    end

    markup
  end
end
