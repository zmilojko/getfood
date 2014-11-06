require 'net/http'
BASE_LINK = "http://www.etlistat.fi/tuotteet/"


def connect
  @http = Net::HTTP.new('www.etlistat.fi', 80)
  @http.use_ssl = false
  r = @http.get(BASE_LINK)
  #@cookie = {'Cookie'=>r.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join}
end

def get_page url
  connect if @http.nil?
  resp = @http.get url #,@cookie
  page = resp.body
end

def scan_all_categories
  page = get_page BASE_LINK
  page.scan(/<a href="tuotteet\/(\S+\/)">/).each do |category|
    get_listat category[0]
  end
end

def get_listat category
  page = get_page(BASE_LINK + category)
  page.scan(/<a class="(first )?white-border-box product-listing-box" href="\/tuotteet\/(\S+\/\S+.html)"/).each do |product|
    get_lista category.gsub("/",""), product[1]
  end
end

def get_lista category, product
  page = get_page(BASE_LINK + product)
  product_code = page.scan(/<h1>([A-Z0-9]+)<br/)[0][0]
  product_name = page.scan(/<h1>\S+<br ?\/>(.+)<br/)[0][0].gsub("<br />", ", ")
  if page.scan(/<td>(\d{10,})<\/td>/).length > 0
    product_ean = page.scan(/<td>(\d{10,})<\/td>/)[0][0] 
    puts %("#{category}","#{product_code}","#{product_name}",#{product_ean})
    STDOUT.flush
  else 
    #puts "ERROR!!! no EAN on page #{category}/#{product}"
    STDOUT.flush
  end
end

scan_all_categories
