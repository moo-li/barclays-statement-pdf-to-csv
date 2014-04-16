require 'csv'
desc 'Parse all PDFs in doc folder'
task :parse => :environment do
  DATE_WIDTH      = 13  
  NARRATIVE_WIDTH = 34
  PAYMENT_WIDTH   = 14
  RECEIPT_WIDTH   = 14
  BALANCE_WIDTH   = 12

  Dir.glob('doc/pdf/*.pdf') do |pdf_file|
    pdf_file_name     = pdf_file.chomp('.pdf')[4..-1]
    csv_file_name     = "doc/csv/#{pdf_file_name}.csv"
    reader            = PDF::Reader.new(pdf_file)
    
    CSV.open(csv_file_name, "wb") do |csv_file|
      csv_file << ["Date", "Details", "Payments","Receipts","Balance"]
    end

    reader.pages.each do |page|
      
      # for getting account details
      lines_all = page.text.lines.map(&:chomp)
      lines_wanted = []
      
      start_point = 0
      custom_start_point = 0
      
      lines_all.each_with_index do |line,index|        
        one = line.split.include?("Date")
        two = line.split.include?("Description")
        three =line.split.include?("Money")
        four = line.split.include?("Balance")
        
        if one && two && three && four
          start_point = index
        end
      end
      
      lines_all.each_with_index do |line,index|        
        one = line.split.include?("Start")
        two = line.split.include?("balance")
        
        if one && two
          lines_all.delete_at(index)
        end
      end
 
      end_point = lines_all.map(&:strip).find_index("Continued")
            
      lines_all.each_with_index do |line,i|
        lines_wanted << line if i > start_point.to_i && i < end_point.to_i
      end

      line_date_list = []

      lines_wanted.each_with_index do |line, i|
        
        # Date
        current_date = ""
        data = line.split(/\s{2,}/)
        line_date_striped = data[0]
        if line_date_striped =~ /\A\d{1,2} \w{3}\z/
          line_date_list << line_date_striped
          
          current_date = "#{line_date_striped}"
        else
          current_date = "#{line_date_list.last}"
        end

        # Narrative
        leftmost = 0
        leftmost += DATE_WIDTH
        line_narrative = ""
        line_narrative = data[1]
        
        # Payments
        leftmost += NARRATIVE_WIDTH
        payment = 0
        if line.length > leftmost
          payment_raw = line[leftmost, PAYMENT_WIDTH]
          payment = payment_raw.gsub(',', '').to_f
        end

        # Receipts
        leftmost += PAYMENT_WIDTH
        receipt = 0
        if line.length > leftmost
          receipt_raw = line[leftmost, RECEIPT_WIDTH]
          receipt = receipt_raw.gsub(',', '').to_f
        end

        # Balance
        leftmost += RECEIPT_WIDTH
        balance = 0
        if line.length > leftmost
          balance_raw = line[-BALANCE_WIDTH, BALANCE_WIDTH]
          balance = balance_raw.gsub(',', '').to_f
        end

        @csv_line = []
        @csv_line << current_date
        @csv_line << line_narrative
        @csv_line << payment
        @csv_line << receipt
        @csv_line << balance
          
          if payment > 0.001 || receipt > 0.001
            # content << csv_line
            CSV.open(csv_file_name, "a+") do |csv|
              csv << @csv_line
            end
            puts "added #{@csv_line} into #{csv_file_name}"    
          end
          end
        end
  end
end
