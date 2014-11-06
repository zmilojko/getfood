require 'net/http'
BASE_LINK = "https://www.k-ruokakauppa.fi/k-supermarket-hameenkyla/tuotteet"

baba = %w{
  103582 103612 103677 103750 103794 104061 104144 103883 103914 105351 105244}

def connect
  @http = Net::HTTP.new('www.k-ruokakauppa.fi', 443)
  @http.use_ssl = true
  r = @http.get("https://www.k-ruokakauppa.fi/k-supermarket-hameenkyla/tuotteet/226921")
  @cookie = {'Cookie'=>r.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join}
end

def get_page url
  connect if @cookie.nil?
  resp = @http.get url ,@cookie
  page = resp.body
end

def get_products_from_category car_id
  page = get_page "https://www.k-ruokakauppa.fi/k-supermarket-hameenkyla/alakategoria/#{car_id}"
  page.scan(/<a id="product_(\d+)" class="product_link"/).each do |tuote|
    getdata tuote[0]
  end
  #puts "trying subpages for #{car_id}"
  #also get additional pages
  i=0
  page.scan(/k\-supermarket\-hameenkyla\/alakategoria\/(\d+)\?page\.currentPage\=(\d+)/).each do |add_page|
    i = add_page[1].to_i
  end
  if i>1
    (2..i).each do |pagenumber|
      page = get_page "https://www.k-ruokakauppa.fi/k-supermarket-hameenkyla/alakategoria/#{car_id}?page.currentPage=#{pagenumber}"
      page.scan(/<a id="product_(\d+)" class="product_link"/).each do |tuote|
        #puts "category #{car_id} page #{pagenumber}"
        getdata tuote[0]
      end
    end
  end
end

def getdata tuoteno
  page = get_page "#{BASE_LINK}/#{tuoteno}"
  ean = page[/EAN-koodi: (\d+)/,1]
  name = page[/\<h1\>(.*)\<\/h1\>/,1]
  if not ean.nil?
    puts "\"#{name}\",#{ean}"
    $stdout.flush
  end
end

#getdata 226921

#(216000..239999).each do |tuote|
#  getdata tuote
#end

#page = get_products_from_category 103582

#get_products_from_category ARGV[0]

baba.each do |cat|
  get_products_from_category cat
end

