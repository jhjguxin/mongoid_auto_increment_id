# encoding: UTF-8
###########################################
# FIXME
# 使用 mongoid_auto_increment_id.rb 会产生一个 bug
# 如果应用需要引用原始形式的 Moped::BSON::ObjectId 的时候带有 "_id" 后缀形式的的外建会失效
# 但是不规范的 'report_id', 'test_report_id' 则可以工作
# 如果没有使用 外建则没有这样的问题 'gx_report_id', 'report_id', 'test_report_id' 则可以工作
# GxReportNote.create(handle_user_id: "6", report_id: "5153d50bd282b8b3a8000017", gx_report_id: "5153d50bd282b8b3a8000017", handle_item: "1", handle_info: "123", test_report_id: "5153d50bd282b8b3a8000017")
# <GxReportNote _id: 22, created_at: 2013-05-06 13:03:12 UTC, updated_at: 2013-05-06 13:03:12 UTC, handle_user_id: 6, gx_report_id: 0, report_id: "5153d50bd282b8b3a8000017", test_report_id: "5153d50bd282b8b3a8000017", handle_item: "1", handle_info: "123">
# gx_report_id: 0 变成了 0
# GxReportNote.create(handle_user_id: "6", report_id: "5153d50bd282b8b3a8000017", gx_report_id: "1", handle_item: "1", handle_info: "123", test_report_id: "5153d50bd282b8b3a8000017")
# <GxReportNote _id: 26, created_at: 2013-05-06 13:04:51 UTC, updated_at: 2013-05-06 13:04:51 UTC, handle_user_id: 6, gx_report_id: 1, report_id: "5153d50bd282b8b3a8000017", test_report_id: "5153d50bd282b8b3a8000017", handle_item: "1", handle_info: "123">

# 尝试把
# 'Mongoid::Identity.generate_id' return set as string
# field :_id, :type => String
# 则基本上能 work
###########################################
module Mongoid
  class Identity
    # Generate auto increment id
    def self.generate_id(document)
      o = Mongoid::Sessions.default.command({:findAndModify => "mongoid.auto_increment_ids",
                                             :query  => { :_id => document.collection_name },
                                             :update => { "$inc" => { :c => 1 } },
                                             :upsert => true,
                                             :new    => true })
      #o["value"]["c"].to_i
      o["value"]["c"].to_i.to_s
    end
  end

  module Document
    # define Integer for id field
    included do
      #field :_id, :type => Integer
      field :_id, :type => String
    end

    # hack id nil when Document.new
    def identify
      Identity.new(self).create
      nil
    end

    alias_method :super_as_document,:as_document
    def as_document
      result = super_as_document
      if result["_id"].blank?
        result["_id"] = Identity.generate_id(self)
      end
      result
    end
  end
end
