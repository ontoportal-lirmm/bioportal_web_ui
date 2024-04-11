module UrlsHelper
    def escape(string)
        CGI.escape(string) if string
    end

    def unescape(string)
        CGI.unescape(string) if string
    end
end
