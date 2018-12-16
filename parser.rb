#! /bin/ruby

require 'date'
require 'json'
require 'set'

def create_year_file(year)
  file = File.open("_monthly/#{year}.html", 'w')
  file.write("---
layout: monthly
generated: #{Time.now}
---

{% for value in site.data.allmy['#{year}'].months %}
{% cycle 'add row' : '<div class=\"boxes-tables pure-g\">', '', '' %}
  {% assign data = value[1] %}
  {% include monthly.html data=data %}
  {% cycle 'end row' : '', '', '</div>' %}
{% endfor %}
{% cycle 'end row' : '', '</div>', '</div>' %}
")
  file.close
end

def days_in_month(year, month)
  Date.new(year.to_i, month.to_i, -1).day
end

def days_drinking(start_date)
  year = start_date.year
  if year == Date.today.year
    end_date = Date.today
  else
    end_date = Date.new(year, 12, 31)
  end

  (end_date - start_date.to_date).to_i + 1
end

def populate(filename)
  years = {}
  file = File.read(filename)
  untappd_json = JSON.parse(file)

  rows = 0
  untappd_json.each do | check_in |
    checked_in = DateTime.parse(check_in['created_at'])
    year = checked_in.year.to_s
    month = checked_in.month.to_s
    day = checked_in.day.to_s

    unless years[year]
      years[year] = {
        'months' => {},
        'checkins' => Set[],
        'unique_beers' => Set[],
        'unique_breweries' => Set[],
        'brewery_countries' => Set[],
        'unique_venues' => Set[],
        'venue_countries' => Set[],
        'max_abv' => -1.0,
        'avg_abv' => 0,
        'start_date' => checked_in,
        'most_per_day' => {
          'checkins' => 0,
          'checkins_date' => nil,
          'unique_beers' => 0,
          'unique_beers_date' => nil,
        }
      }
    end

    unless years[year]['months'][month]
      years[year]['months'][month] = {
        'name' => checked_in.strftime("%B"),
        'checkins' => Set[],
        'unique_beers' => Set[],
        'unique_breweries' => Set[],
        'brewery_countries' => Set[],
        'unique_venues' => Set[],
        'venue_countries' => Set[],
        'max_abv' => -1.0,
        'avg_abv' => -1.0,
        'days' => {},
        'most_per_day' => {
          'checkins' => 0,
          'checkins_date' => nil,
          'unique_beers' => 0,
          'unique_beers_date' => nil,
        }
      }
    end

    unless years[year]['months'][month]['days'][day]
      years[year]['months'][month]['days'][day] = {
        'checkins' => Set[],
        'unique_beers' => Set[]
      }
    end

    years[year]['months'][month]['days'][day]['checkins'].add(check_in['checkin_id'])
    years[year]['months'][month]['days'][day]['unique_beers'].add(check_in['bid'])

    years[year]['months'][month]['checkins'].add(check_in['checkin_id'])
    years[year]['months'][month]['unique_beers'].add(check_in['bid'])
    years[year]['months'][month]['unique_breweries'].add(check_in['brewery_id'])
    years[year]['months'][month]['brewery_countries'].add(check_in['brewery_country']) if check_in['brewery_country']
    years[year]['months'][month]['unique_venues'].add(check_in['venue_name']) if check_in['venue_name']
    years[year]['months'][month]['venue_countries'].add(check_in['venue_country']) if check_in['venue_country']

    if years[year]['months'][month]['max_abv'] < check_in['beer_abv'].to_f
      years[year]['months'][month]['max_abv'] = check_in['beer_abv'].to_f
    end
    years[year]['months'][month]['avg_abv'] += check_in['beer_abv'].to_f

    years[year]['avg_abv'] += check_in['beer_abv'].to_f
    years[year]['checkins'].add(check_in['checkin_id'])
    years[year]['unique_beers'].add(check_in['bid'])
    years[year]['unique_breweries'].add(check_in['brewery_id'])
    years[year]['brewery_countries'].add(check_in['brewery_country']) if check_in['brewery_country']
    years[year]['unique_venues'].add(check_in['venue_name']) if check_in['venue_name']
    years[year]['venue_countries'].add(check_in['venue_country']) if check_in['venue_country']
  end

  years.each do | year_number, year |
    year['months'].each do | month_number, month |
      month['days'].each do | day_number, day |
        if month['most_per_day']['checkins'] < day['checkins'].size
          month['most_per_day']['checkins'] = day['checkins'].size
          month['most_per_day']['checkins_date'] = Date.new(year_number.to_i, month_number.to_i, day_number.to_i)
        end
        if month['most_per_day']['unique_beers'] < day['unique_beers'].size
          month['most_per_day']['unique_beers'] = day['unique_beers'].size
          month['most_per_day']['unique_beers_date'] = Date.new(year_number.to_i, month_number.to_i, day_number.to_i)
        end
      end
      month.delete('days')

      if year['max_abv'] < month['max_abv']
        year['max_abv'] = month['max_abv']
      end
      if year['most_per_day']['checkins'] < month['most_per_day']['checkins']
        year['most_per_day']['checkins'] = month['most_per_day']['checkins']
        year['most_per_day']['checkins_date'] = month['most_per_day']['checkins_date']
      end
      if year['most_per_day']['unique_beers'] < month['most_per_day']['unique_beers']
        year['most_per_day']['unique_beers'] = month['most_per_day']['unique_beers']
        year['most_per_day']['unique_beers_date'] = month['most_per_day']['unique_beers_date']
      end

      month['checkins'] = month['checkins'].size
      month['unique_beers'] = month['unique_beers'].size
      month['unique_breweries'] = month['unique_breweries'].size
      month['brewery_countries'] = month['brewery_countries'].size
      month['unique_venues'] = month['unique_venues'].size
      month['venue_countries'] = month['venue_countries'].size
      month['avg_abv'] = (month['avg_abv'] / days_in_month(year_number, month_number).to_f).round(2)
      month['beers_per_day'] = (month['checkins'] / days_in_month(year_number, month_number).to_f).round(2)
    end

    year['checkins'] = year['checkins'].size
    year['unique_beers'] = year['unique_beers'].size
    year['unique_breweries'] = year['unique_breweries'].size
    year['brewery_countries'] = year['brewery_countries'].size
    year['unique_venues'] = year['unique_venues'].size
    year['venue_countries'] = year['venue_countries'].size
    year['avg_abv'] = (year['avg_abv'] / year['checkins'].to_f).round(2)
    year['beers_per_day'] = (year['checkins'] / days_drinking(year['start_date']).to_f).round(2)

    # TODO: Only write file if new api-version
    create_year_file(year_number)
  end
  return years
end

if __FILE__ == $PROGRAM_NAME
  filename = ARGV[0]

  unless filename
    p 'Missing file'
    p 'ruby parser.rb untappd-05-02-2018.json'
    exit(1)
  end

  unless File.file?(filename)
    p "Can't find #{filename}"
    exit(1)
  end

  data = populate(filename)
  File.open("_data/allmy.json", "w") do |f|
    f.write(data.to_json)
  end
end