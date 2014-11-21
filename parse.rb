start = ["Autonvaraosat"]

def process_folder indentation: 0, folder: nil
  i = indentation
  raise "You have to specify folder, relative to where you are, pretty much" unless folder
  Dir.chdir folder do
    puts "#{" "*i}{"
    subdirectories = Dir.glob('*').select {|f| File.directory? f}
    files = Dir.glob('*').select {|f| not File.directory? f} - %w(index.html links.txt)
    puts %(#{" "*(i+2)}name: "#{folder}",)
    unless subdirectories.empty?
      puts "#{" "*(i+2)}subcategories: ["
      subdirectories.each do |subcategory|
        process_folder indentation: (i+4), folder: subcategory
      end
      puts "#{" "*(i+2)}],"
    end
    unless files.empty?
      puts "#{" "*(i+2)}products: ["
      files.each do |filename|
        content = File.read(filename)
        name = content.match(%r{<h1 class="articleTitle">([^<]+)</h1>})[1]
        id = filename.match(%r{(\d+)$})[1]
        price = content.match(%r{<div class="pricePart">(\d+,?\d*)[^<]*<div class="currencyType">})[1].gsub(",",".")
        puts %(#{" "*(i+4)}{)
        puts %(#{" "*(i+4)}  pid: "#{id}",)
        puts %(#{" "*(i+4)}  name: "#{name.gsub("\"","\\\"")}",)
        puts %(#{" "*(i+4)}  price: #{price},)
        content.gsub! "\r", ""
        content.gsub! "\n", ""
        image_id = content.match(%r{<div class="articleImg">\s*<a class="lightbox cboxElement" href="http://images.biltema.com/PAXToImageService.svc/product/large/20000(\d+)"})[1]
        puts %(#{" "*(i+4)}  image_id: #{image_id},)
        sopii_result = content.match(%r{(<h2>Sopii</h2>.{1,300}</section>)})
        if sopii_result
          puts %(#{" "*(i+6)}sopii: [)
          sopii_result[1].scan(%r{<h2 class="smalltext">([^<]+)</h2>}) do |s|
            brand = s[0].match(%r{^([^:]+)})[1]
            list_of_models = s[0].gsub(brand,"").scan(%r{([A-Za-z0-9\-]+)}).
              map{|m|%("#{m[0]}")}.join(",")
            puts %(#{" "*(i+8)}{brand: "#{brand}", models: [#{list_of_models}]},)
          end
          puts %(#{" "*(i+6)}],)
        end
        puts %(#{" "*(i+4)}},)
      end
      puts "#{" "*(i+2)}],"
    end
    puts "#{" "*i}}#{"," if i > 0}"
  end
end

process_folder folder: "Autonvaraosat"