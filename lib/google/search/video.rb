module Google
  module Search
    class Video < Base
      def query(query,&cb)
        x = cb
        query_for_index( query, 'video') {|body| x.call(body) }
      end
    end
  end
end
