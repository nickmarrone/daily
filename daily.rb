#!/usr/bin/env ruby

require 'highline'
require 'json'
require 'chronic'
require 'optparse'

def main
	journal_location = 'journal.json'
	OptionParser.new do |opts|
		opts.banner = "Usage: daily.rb [options]"
		opts.on('-j', '--journal FILENAME', String, 'Journal location') { |v| journal_location = v }
	end.parse!

	cli = HighLine.new
	cli.say "Welcome to Daily journal editor.\n\n"

	entries = load_entries(journal_location)
	new_entries = []

	loop do
		cli.choose do |menu|
			menu.prompt = "What would you like to do?"
			
			menu.choice('Write a journal entry') do 
				entry = write_entry(cli)
				entries[entry['date']] << entry
				new_entries << entry
			end
			
			menu.choice('View journals') do 
				view_entries(cli, entries)
			end
			
			menu.choice('Exit') do
				output_new_entries(new_entries, journal_location)
				exit(0)
			end
		end
	end
end

def write_entry(cli)
	date = cli.ask 'When?'
	journal = cli.ask 'What happened?'

	{ 
		'date' => Chronic.parse(date).strftime('%Y-%m-%d'),
		'journal' => journal,
	}
end

def view_entries(cli, entries)
	puts "\n"
	entries.values.flatten.sort{ |a, b| a['date'] <=> b['date'] }.each do |entry|
		puts "#{entry['date']}: #{entry['journal']}"
	end
	puts "\n"
end

def load_entries(location)
	entries = Hash.new{ |h, k| h[k] = [] }
	if File.exist?(location)
		File.open(location).each do |line|
			entry = JSON.parse(line)
			entries[entry['date']] << entry
		end
	end

	entries
end

def output_new_entries(entries, location)
	File.open(location, 'a') do |out|
		entries.each do |entry|		
			out.puts entry.to_json
		end
	end
end

main
