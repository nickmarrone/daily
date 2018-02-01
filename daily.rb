#!/usr/bin/env ruby

require 'tty-prompt'
require 'json'
require 'chronic'
require 'optparse'

def main
  journal_location = 'journal.json'
  OptionParser.new do |opts|
    opts.banner = 'Usage: daily.rb [options]'
    opts.on('-j', '--journal FILENAME', String, 'Journal location') { |v| journal_location = v }
  end.parse!

  cli = TTY::Prompt.new
  cli.say 'Welcome to Daily journal editor.\n\n'

  entries = load_entries(journal_location)
  new_entries = []

  loop do
    answer = cli.select('What would you like to do?') do |menu|
      menu.choice 'Write a journal entry', 'write'
      menu.choice 'View journals', 'view'
      menu.choice 'Exit', 'exit'
    end

    case answer
    when 'write'
      entry = write_entry(cli)
      entries[entry['date']] << entry
      new_entries << entry
    when 'view'
      view_entries(cli, entries)
    when 'exit'
      output_new_entries(new_entries, journal_location)
      exit(0)
    else
      cli.say('Invalid option')
    end
  end
end

def write_entry(cli)
  date = cli.ask('When?', required: true, default: 'today') do |q|
    q.validate -> (d) { !Chronic.parse(d).nil? }, 'Please enter a valid date or time (Ex: 3/15/2017, yesterday, last Saturday)'
  end

  journal = cli.multiline('What happened?', required: true).join

  { 
    'date' => Chronic.parse(date).strftime('%Y-%m-%d'),
    'journal' => journal,
  }
end

def view_entries(cli, entries)
  puts "\n"
  entries.values.flatten.sort{ |a, b| a['date'] <=> b['date'] }.each do |entry|
    cli.say(entry['date'], color: :green)
    cli.say("#{entry['journal']}\n")
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
