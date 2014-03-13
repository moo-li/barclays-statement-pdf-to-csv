desc 'Parse all PDFs in doc folder'
task :parse => :environment do
  DATE_WIDTH      = 7
  NARRATIVE_WIDTH = 61
  PAYMENT_WIDTH   = 21
  RECEIPT_WIDTH   = 17
  BALANCE_WIDTH   = 17

  csv = {} # We'll build one CSV file for each account

  Dir.glob('doc/*.pdf') do |pdf_file|
    text_file_name    = 'doc/account-details-not-found.txt'
    csv_file_name     = 'doc/account-details-not-found.csv'
    text              = ''
    reader            = PDF::Reader.new(pdf_file)
    current_year      = nil # define it outside the block
    computed_balance  = nil # define it outside the block

    reader.pages.each do |page|
      lines = page.text.lines.map(&:chomp)

      if page.number == 1
        # Date range
        date_text       = lines[4].split('Statement for ')[1]
        dates           = date_text.split ' - '
        end_year        = dates[1].split[2]
        start_date_text = dates[0]

        if start_date_text.count(' ') == 1
          start_year      = end_year
          start_date_text = "#{start_date_text} #{start_year}"
        else
          start_year      = start_date_text.split[2]
        end

        # If first statement line is a January line no need to increment year
        increment_year_in_jan = false

        current_year    = start_year.to_i

        # Account details
        account_details = lines[5].split
        account_number  = account_details[2]
        sort_code       = account_details[5]
        text_file_name  = "doc/#{sort_code}-#{account_number}-#{start_date_text.to_date}-#{dates[1].to_date}.txt"
        csv_file_name   = "doc/#{sort_code}-#{account_number}.csv"
        csv[csv_file_name] = '' unless csv[csv_file_name]
      else
        text += "\n"
      end

      text += page.text

      current_date  = nil # define it outside the block
      within_lines  = false # true when we're amongst the actual detail lines
      narrative     = [] # Multi-line narrative

      lines.each do |line|
        # Date
        leftmost  = 0
        line_date = line[leftmost, DATE_WIDTH].strip

        if line_date =~ /\A\d{1,2} \w{3}\z/
          # Maybe increment the year if this is a January line?
          if line_date.split[1] == 'Jan'
            if increment_year_in_jan
              current_year += 1

              # Only increment the year once no matter how many January lines
              increment_year_in_jan = false
            end
          else
            # As soon as we see a non-January line we can get ready to
            # increment the year when we next see a January one
            increment_year_in_jan = true
          end

          current_date = "#{line_date} #{current_year}".to_date
        end

        # Narrative
        leftmost += DATE_WIDTH

        if line.length > leftmost
          line_narrative_raw = line[leftmost, NARRATIVE_WIDTH]
          line_narrative = line_narrative_raw.strip
        end

        # Payments
        leftmost += NARRATIVE_WIDTH

        if line.length > leftmost
          payment_raw = line[leftmost, PAYMENT_WIDTH]
          payment = payment_raw.gsub(',', '').to_f
        end

        # Receipts
        leftmost += PAYMENT_WIDTH

        if line.length > leftmost
          receipt_raw = line[leftmost, RECEIPT_WIDTH]
          receipt = receipt_raw.gsub(',', '').to_f
        end

        # Balance
        leftmost += RECEIPT_WIDTH

        if line.length > leftmost
          balance_raw = line[-BALANCE_WIDTH, BALANCE_WIDTH]
          balance = balance_raw.gsub(',', '').to_f
        end

        # Are we amongst the actual statement detail lines?
        if [
          'Balance carried forward',
          'Interim balance carried forward'
          ].include?(line_narrative) || line == 'Continued'
          within_lines  = false
        end

        if within_lines && line_narrative
          narrative << line_narrative

          # Check balance
          computed_balance  = balance if balance && !computed_balance
          computed_balance += receipt if receipt
          computed_balance -= payment if payment

          if balance
            unless (balance - computed_balance).abs < 0.001
              File.open(text_file_name, 'w') { |file| file.write(text) }

              puts  "line_narrative: [#{line_narrative_raw}]"
              puts  "payment: [#{payment_raw}]"
              puts  "receipt: [#{receipt_raw}]"
              puts  "balance: [#{balance_raw}]"

              raise "Balance fail: statement says #{balance}, transactions add up to #{computed_balance}"
            end
          end

          # Transaction
          if payment || receipt
            amount = (payment || 0.0) - (receipt || 0.0)

            puts "#{page.number}\t#{current_date}\t#{amount}\t#{narrative.join(' ').strip}\t(#{payment},#{receipt},#{balance})"
            csv[csv_file_name] += "#{current_date},#{amount},\"#{narrative.join(' ').strip}\"\n"
            narrative = []
          end
        end

        if [
          'Balance brought forward',
          'Interim balance brought forward'
          ].include?(line_narrative)
          within_lines      = true
          narrative         = []
          computed_balance  = balance
        end
      end
    end

    File.open(text_file_name, 'w') { |file| file.write(text) }
  end

  # Write CSV files
  csv.each do |csv_file_name, content|
    File.open(csv_file_name, 'w') { |file| file.write(content) }
  end
end
