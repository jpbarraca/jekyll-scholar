module Jekyll
  class Scholar

    class Details < Page
      include Scholar::Utilities

      def initialize(site, base, dir, entry)
        @site, @base, @dir = site, base, dir

        @config = Scholar.defaults.merge(site.config['scholar'] || {})

        @name = details_file_for(entry)

        process(@name)
        read_yaml(File.join(base, '_layouts'), config['details_layout'])

        liquidify(entry)
      end

	  private

      def liquidify(entry)
        data['entry'] = {}

        data['entry']['key'] = entry.key
        data['entry']['type'] = entry.type

        entry.fields.each do |key, value|
          data['entry'][key.to_s] = value.to_s
        end

        data['entry']['bibtex'] = entry.to_s
        data['entry']['bibtex_simple'] = entry.to_s.sub(%r{^[\s]*abstract[\s]*=[\s]*.*$\n},"").sub(%r{^[\s]*date-[a-z]+[\s]*=[\s]*.*$\n},"")
		data['entry']['pdf'] = File.join(pdfs_path,entry.title.to_s+".pdf")
      end


    end

    class DetailsGenerator < Generator
      include Scholar::Utilities

      safe true
      priority :high

      attr_reader :config

      def generate(site)
        @site, @config = site, Scholar.defaults.merge(site.config['scholar'] || {})

        if generate_details?
          entries.each do |entry|
            details = Details.new(site, site.source, File.join('', details_path), entry)
            details.render(site.layouts, site.site_payload)
            details.write(site.dest)

			begin
			  srcfile = File.join(pdfs_path,entry.title.to_s+".pdf")
			  destfile = File.join(details_path,"pdf",entry.key+".pdf")

			  if File.exists?(destfile)
			  	FileUtils.rm(destfile)
			  end

			  FileUtils.copy(File.expand_path(srcfile),destfile)

			rescue Exception => e
		  	  puts "ERROR: Unable to copy file: "+e.message
			end
            site.pages << details
          end

        end
      end

    end


  end
end
