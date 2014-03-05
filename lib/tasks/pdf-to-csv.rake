desc 'Parse all PDFs in doc folder'
task :parse => :environment do
  Dir.glob('doc/*.pdf') do |pdf_file|
    puts pdf_file # debug
  end
end
