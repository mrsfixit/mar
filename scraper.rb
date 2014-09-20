class MelbAuctResults
  include Enumerable

  def cols
    @cols ||= %w(address beds_s price_s type method sale_date agent).map(&:to_sym)
  end

  def agent
    @agent ||= Mechanize.new
  end

  def each
    ('A'..'Z').map do |letter|
      page = agent.get("http://www.realestateview.com.au/propertydata/auction-results/victoria/#{letter}")
      if (x = page.at('div.pd-table'))
        suburb_names = x.xpath("//div[@class='pd-content-heading-dark']").map { |n|
          n.text.strip[/^(.*) Sales & Auction Results$/, 1]
        }
        suburb = nil
        x.xpath("//div[@class='pd-table']/*/*/tr").map { |n0|
          n0.xpath('td').map { |n| n.text.gsub(/[[:space:]]+/, ' ').strip }.compact
        }.inject({}) { |h, result|
          if result.empty?
            suburb = suburb_names.shift
          else
            h = Hash[cols.zip(result)].merge(suburb: suburb)
            h[:beds] = h[:beds_s].to_i
            h[:price] = h[:price_s].gsub(/[^\d]/, '').to_i
            h[:sale_date] = Date.parse(h[:sale_date])
            yield h
          end
        }
      end
    end
  end

  def save
    ScraperWiki.save_sqlite(%w(sale_date address suburb).map(&:to_sym), to_a)
  end
end

MelbAuctResults.new.save
