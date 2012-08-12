require 'nokogiri'

module NexusCli
  module N3Metadata
    class << self
      def generate_n3_path(group_id, artifact_id, version, extension, repository)
        return "content/repositories/#{repository}/.meta/#{group_id.gsub(".", "/")}/#{artifact_id.gsub(".", "/")}/#{version}/#{artifact_id}-#{version}.#{extension}.n3"
      end

      # Generates the Nexus .n3 header for the tempfile that will be used to update an artifact's custom metadata.
      def generate_n3_header(group_id, artifact_id, version, extension)
        return "<urn:maven/artifact##{group_id}:#{artifact_id}:#{version}::#{extension}> a <urn:maven#artifact>"
      end

      # Generates a hash containing the Nexus .n3 contents for the tempfile that will be used to update an artifact's custom metadata.
      # If a hash of n3 user urns is provided, the contents will override existing key/value pairs.
      def generate_n3_contents_from_n3(contents, n3_user_urns)
        n3_user_urns ||= Hash.new
        contents.each_line do |line|
          if line.match(/urn:nexus\/user#/)
            tag, value = parse_n3_item(line)
            # Delete the nexus key if the local key has no value.
            if n3_user_urns.has_key?(tag) && value.empty?
              n3_user_urns.delete(tag)
            else
              n3_user_urns[tag] = generate_n3_item(tag, value) unless tag.empty? || value.empty?
            end
          end
          return n3_user_urns
        end
      end

      def generate_n3_contents_from_hash(contents, n3_user_urns)
        n3_user_urns = Hash.new
        contents.each do |tag, value|
          n3_user_urns[tag] = generate_n3_item(tag, value) unless tag.empty? || value.empty?
        end
        return n3_user_urns
      end

      def parse_n3_hash(contents)
        return contents.values.count == 1 ? contents.values[0] + " ." : contents.values.join(" ;\n") + " ."
      end

      # Returns n3 as XML.
      def n3_to_xml(n3)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send("artifact-resolution") {
            xml.data {
              n3.each_line { |line|
                tag, value = parse_n3_item(line)
                xml.send(tag, value) unless tag.empty? || value.empty?
              }
            }
          }
        end
        return builder.doc.root.to_s
      end

      private
      def parse_n3_item(line)
        tag = line.match(/#(\w*)>/) ? "#{$1}" : ""
        value = line.match(/"([^"]*)"/)  ? "#{$1}" : ""
        return tag, value
      end

      def generate_n3_item(tag, value)
        return "\t<urn:nexus/user##{tag}> \"#{value}\""
      end
    end
  end
end
