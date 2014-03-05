desc 'Parse all PDFs in doc folder'
task :parse => :environment do
  Dir.glob('doc/*.pdf') do |pdf_file|
    text_file_name  = 'doc/account-details-not-found.txt'
    text            = ''
    reader          = PDF::Reader.new(pdf_file)

    reader.pages.each do |page|
      lines = page.text.lines.map(&:chomp)

      if page.number == 1
        # Date range
        date_text       = lines[4].split('Statement for ')[1]
        dates           = date_text.split ' - '
        start_date_text = dates[0]
        start_date_text = "#{start_date_text} #{dates[1].split[2]}" if start_date_text.count(' ') == 1

        # Account details
        account_details = lines[5].split
        account_number  = account_details[2]
        sort_code       = account_details[5]
        text_file_name  = "doc/#{sort_code}-#{account_number}-#{start_date_text.to_date}-#{dates[1].to_date}.txt"
      else
        text += "\n"
      end

      text += page.text

#      lines.each do |line|
#        puts line
#      end
    end

    File.open(text_file_name, 'w') { |file| file.write(text) }
  end
end
