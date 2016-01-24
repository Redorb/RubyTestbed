require 'open-uri'
require 'nokogiri'
require 'json'

class RemoteOkParser
	def grab_front_page_jobs
		front_page_html = Nokogiri::HTML(open("https://remoteok.io/"))
		job_postings_as_json(front_page_html)
	end

	def grab_jobs_by_filter_word filter_word
		filtered_jobs_html = Nokogiri::HTML(open("https://remoteok.io/remote-#{filter_word}-jobs"))
		job_postings_as_json(filtered_jobs_html)
	end

	private
	def job_postings_as_json(html_to_parse)
		job_elements = html_to_parse.css("tr[itemtype='http://schema.org/JobPosting']")
		job_list = job_elements.map do |element|
			job_id = element.attr("data-id")
			job = { 
				:job_name => 
					element.css("a[itemprop='url'] h2").text,
				:company_name => 
					element.css("a[itemprop='hiringOrganization'] h3").text,
				:tags => 
					element.css("td.tags h3").map do |tag| tag.text.split("3>")[0] end,
				:description =>
					map_desc_to_job_as_text(job_id, html_to_parse)
			}

			link = element.css("td.source a").attr("href").value
			job[:link] = link.start_with?('mailto') ? link : "https://remoteok.io#{link}"
			job
		end
		job_list.to_json
	end

	def map_desc_to_job_as_text job_id, html_to_parse
		job_desc_element = html_to_parse.css("tr.expand-#{job_id}")
		job_desc_text = job_desc_element.css("div.description > div:not(.p) p")
		job_desc_text.text
	end
end