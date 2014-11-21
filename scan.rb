require 'net/http'
require 'fileutils'
STDOUT.sync = true

START = "Autoilu---MP"
START_DIR = START.gsub("-","")

HOST = "www.biltema.fi"
BASE_LINK = "http://#{HOST}/fi/#{START}/"

puts "Reloaded!"

def connect
  @http = Net::HTTP.new(HOST, 80)
  @http.use_ssl = false
  r = @http.get(BASE_LINK)
  @cookie = {'Cookie'=>r.to_hash['set-cookie'].collect{|ea|ea[/^.*?;/]}.join}
  r.body
end

def get_page url
  connect if @http.nil?
  resp = @http.get url,@cookie
  page = resp.body
end

def scan_all_categories
  page = get_page BASE_LINK
  categories = page.scan(%r{<li><a href="/fi/Autoilu---MP/(\S*)/">(\S*)</a></li>})
  puts "categories are #{categories.inspect}"
  begin
    Dir.mkdir START_DIR
  rescue
    FileUtils.rm_rf START_DIR
    Dir.mkdir START_DIR
  end
  Dir.chdir START_DIR do
    File.write("#{START_DIR}.html", page)
    categories.each do |category|
      begin
        scan_category category, BASE_LINK
      rescue
        puts "Error position 1, #{category}, #{$!}"
      end
    end
  end
end

def scan_category category, base_link
  category_link = "#{base_link}#{category[0]}/"
  Dir.mkdir category[0]
  Dir.chdir category[0] do
    puts category_link
    page = get_page category_link
    orig_page = String.new(page)
    File.write('index.html', page)
    page.gsub! "\r", ""
    page.gsub! "\n", ""
    page.gsub! /^.*<section class="l-widget subNavContainerMobile">/, ""
    page.gsub! /^.*<section class="l-widget subNavContainerMobile">/, ""
    page.gsub! /<\/ul>.*$/, ""
    File.write('links.txt', page)
    subcategories = page.scan(%r{<li><a href='/fi/Autoilu---MP/(?:[a-zA-Z0-9\-]+/)*([a-zA-Z0-9\-]+)/'>([^<]+)</a></li>})
    if subcategories.empty?
      begin
        scan_this_category orig_page, category_link
      rescue
        puts "Error position 2, #{orig_page}, #{category_link}, #{$!}"
      end
    else
      subcategories.each do |category|
        begin
          scan_category category, category_link
        rescue
          puts "Error position 3, #{category}, #{category_link}, #{$!}"
        end
      end
    end
  end
end
  
def scan_this_category page, category_link
  begin
    scan_this_page page, category_link
  rescue
    puts "Error position 4, #{page}, #{category_link}, #{$!}"
  end
  begin
    regex_max_page = %r{page=(\d+)">(\d+)</a></li>}
    max_page = page.scan(regex_max_page).last[0].to_i
    (2..max_page).each do |page_number|
      other_page_url = "#{category_link}?page=#{page_number}"
      puts other_page_url
      non_first_page = get_page(other_page_url)
      begin
        scan_this_page non_first_page, category_link
      rescue
        puts "Error position 5, #{non_first_page}, #{category_link}, #{$!}"
      end
    end
  rescue
    puts "Error position 6, #{page}, #{category_link}, #{$!}"
  end
end

def scan_this_page page, category_link
  title_regex = %r{<h2 class="productListTitle"><a href='/fi/Autoilu---MP/(?:[a-zA-Z0-9\-]+/)*([a-zA-Z0-9\-]+)/'>([^<]+)</a></h2>}
  products = page.scan(title_regex)
  products.each do |product|
    begin
      product_url = "#{category_link}#{product[0]}/"
      puts product_url
      product_page = get_page(product_url)
      File.write(product[0], product_page)
    rescue
      puts "Error position 7, #{category_link}, #{product[0]}, #{$!}"
    end
  end
end

scan_all_categories