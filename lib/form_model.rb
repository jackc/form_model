class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # TODO: if this is going to be used on an ActiveRecord
    # add check against before_type_cast here if respond to before_type_cast

    return if value == nil
    unless value.is_a? Date
      record.errors.add attribute, 'is not a date'
    end
  end
end

class TimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # TODO: if this is going to be used on an ActiveRecord
    # add check against before_type_cast here if respond to before_type_cast

    return if value == nil
    unless value.is_a? Time
      record.errors.add attribute, 'is not a time'
    end
  end
end

class TimeOfDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # TODO: if this is going to be used on an ActiveRecord
    # add check against before_type_cast here if respond to before_type_cast

    return if value == nil
    unless value.is_a? TimeOfDay
      record.errors.add attribute, 'is not a time of day'
    end
  end
end

class FormModel
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def self.attr_string(name, validations=nil)
    attr_reader name
    define_method "#{name}=" do |value|
      instance_variable_set "@#{name}", value.to_s
    end
    validates name, validations if validations
  end

  def self.attr_integer(name, validations={})
    attr_reader name
    define_method "#{name}=" do |value|
      value = Integer(value) rescue value
      instance_variable_set "@#{name}", value
    end

    validations[:numericality] = if validations[:numericality].is_a?(Hash)
      validations[:numericality].merge(:only_integer => true)
    else
      { :only_integer => true }
    end
    validates name, validations
  end

  def self.attr_date(name, validations={})
    attr_reader name
    define_method "#{name}=" do |value|
      value = Date.strptime(value, "%m/%d/%Y") rescue value
      instance_variable_set "@#{name}", value
    end
    validations = validations.merge(:date => true)
    validates name, validations
  end

  def self.attr_time(name, validations={})
    attr_reader name
    define_method "#{name}=" do |value|
      value = Time.parse(value) rescue value
      instance_variable_set "@#{name}", value
    end
    validations = validations.merge(:time => true)
    validates name, validations
  end

  def self.attr_time_of_day(name, validations={})
    attr_reader name
    define_method "#{name}=" do |value|
      value = TimeOfDay.parse(value) rescue value
      instance_variable_set "@#{name}", value
    end
    validations = validations.merge(:time_of_day => true)
    validates name, validations
  end

  def initialize(attributes={})
    attributes.each do |k,v|
      send "#{k}=", v
    end
  end
  
  def persisted?
    false
  end
end
