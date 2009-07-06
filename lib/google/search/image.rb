module Google
  module Search
    class Image < Base
      def query(query,&cb)
        x = cb
        query_for_index( query, 'image' ) {|body| x.call(body) }
      end
    end
  end
end
