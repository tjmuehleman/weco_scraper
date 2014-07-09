class ScraperController < ApplicationController
  require 'open-uri'
  
  def index

  	5.times do |i|
  		i = i + 1
  		puts "???????????????????????????????????"
  		puts "Working on http://www.yellowpages.com/atlanta-ga/restaurants?g=Dallas%2C+TX&page=#{i}&s=relevance"
  		#news_tmp_file = open("http://www.yellowpages.com/atlanta-ga/restaurants?g=Atlanta%2C+GA&page=#{i}&s=relevance")
  		news_tmp_file = open("http://www.yellowpages.com/atlanta-ga/restaurants?g=Dallas%2C+TX&page=#{i}&s=relevance")

  		city = "DALLAS"
  		city_id = 5

		# Parse the contents of the temporary file as HTML
		doc = Nokogiri::HTML(news_tmp_file)

		#items = doc.css(".info-section-wrapper")
		items = doc.search('div[@itemtype="http://schema.org/LocalBusiness"]')
		items.each do |item|
			begin

				name = item.search('span[@itemprop="name"]').text
				address = item.search('span[@itemprop="streetAddress"]').text
				city = item.search('span[@itemprop="addressLocality"]').text.sub! ", ", ""
				state = item.search('span[@itemprop="addressRegion"]').text
				postalcode = item.search('span[@itemprop="postalCode"]').text

				if address != nil && city != nil && state != nil

					coordinates = lat_long_finder(address, city, state)

					latitude = coordinates[0]
					longitude = coordinates[1]		
					
					yp_url = item.css("a")[0].attr("href")
					# url to their website
					web_url = item.css("a")[3].attr("href")
					email = get_email_address(yp_url)
					
					# only save if there's a valid email
					if email != nil
						puts '************SAVING ' + name

						#  def save_venue(venuefsid, name, lat, long, email, websiteurl, city_id, city)
						guid = generate_guid

						# create the venue
						save_venue(guid, name, latitude, longitude, email, web_url, city_id, city, address, state, postalcode)
						# create the job posting
						create_job_post(guid, city, email, name)

						#render :text => "done" and return

						
					end
				end
			rescue => e
				render :text => e and return
				next
			end
		end
	
	end

  end

  def get_email_address(yp_url)
  	news_tmp_file = open("http://www.yellowpages.com#{yp_url}")

	# Parse the contents of the temporary file as HTML
	doc = Nokogiri::HTML(news_tmp_file)

	email_str = doc.css("footer").css("a")[1].attr("href")

	if email_str.starts_with?("mailto:")
		email_str.sub! "mailto:", ""
	else
		nil
	end
  end

  def address_combiner(street, city, state)
     street + ", " + city + ", " + state
  end

  def lat_long_finder(street, city, state)
   	address = address_combiner(street, city, state)
   	coordinates = Geocoder.coordinates(address)
  end

  def generate_guid
  	"WC_" + SecureRandom.uuid.gsub!("-", "").upcase!
  end

  def save_venue(venuefsid, name, lat, longitude, email, websiteurl, city_id, city, address, state, zip)
  	venue = Venue.new
  	venue.FSID = venuefsid
  	venue.NAME = name
  	venue.CITY = city
  	venue.CITY_ID = city_id
  	venue.STREET = address
  	venue.STATE = state
  	venue.POSTCODE = zip

  	venue.LATITUDE = lat
  	venue.LONGITUDE = longitude
  	venue.EMAIL = email
  	venue.VENUE_URL = websiteurl
  	venue.save
  end

  def create_job_post(venuefsid, city, email, name)
  	subject = get_subject
  	description = "#{name} is looking for you! Interested in working for one of the best restaurants in #{city}? We're always looking for great FOH!"

  	posting = Posting.new
  	posting.VENUEFSID = venuefsid
  	posting.CREATION_DATE = Time.now
  	posting.SUBJECT = subject
  	posting.DESCRIPTION = description
  	posting.STATUS = 1
  	posting.EMAIL = email
  	posting.MARKET = city.upcase
  	posting.JOB_CATEGORY_ID = 4 #server
  	posting.save
  end

  def get_subject(name)
  	num = rand(0..5)
  	if num == 0
  		"#{name} looking for FOH"
  	elsif num == 1
  		"Hiring at #{name}"
  	elsif num == 2
  		"Looking for great FOH"
  	elsif num == 3
  		"#{name} wants you!"
  	elsif num == 4
  		"#{name} is one of the best!"
  	elsif num == 5
  		"Seeking great FOH at #{name}"
  	end
  end

  def get_description
  	
  end


end
