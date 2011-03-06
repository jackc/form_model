class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # https://rails.lighthouseapp.com/projects/8994/tickets/6235-activerecord-should-not-silently-discard-values-it-cant-typecast
    # Data could have already been lost in value unless we go back to before type casting
    value = value.is_a?(Date) ? value : record.read_attribute_before_type_cast(attribute)
    
    return if value == nil
    unless value.is_a? Date
      record.errors.add attribute, 'is not a date'
      return
    end
    if options[:earliest]
      earliest = if options[:earliest].is_a?(Date)
        options[:earliest]
      else
        options[:earliest].call
      end
      record.errors.add attribute, 'is too early' if value < earliest
    end
    if options[:latest]
      latest = if options[:latest].is_a?(Date)
        options[:latest]
      else
        options[:latest].call
      end
      record.errors.add attribute, 'is too late' if latest < value
    end
  end
end

class TimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # https://rails.lighthouseapp.com/projects/8994/tickets/6235-activerecord-should-not-silently-discard-values-it-cant-typecast
    # Data could have already been lost in value unless we go back to before type casting
    value = value.is_a?(Time) ? value : record.read_attribute_before_type_cast(attribute)

    return if value == nil
    unless value.is_a? Time
      record.errors.add attribute, 'is not a time'
    end
  end
end

class TimeOfDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # https://rails.lighthouseapp.com/projects/8994/tickets/6235-activerecord-should-not-silently-discard-values-it-cant-typecast
    # Data could have already been lost in value unless we go back to before type casting
    value = value.is_a?(TimeOfDay) ? value : record.read_attribute_before_type_cast(attribute)

    return if value == nil
    unless value.is_a? TimeOfDay
      record.errors.add attribute, 'is not a time of day'
    end
  end
end

module TypeCastingWriters
  def date_writer(attr_name)
    define_method "#{attr_name}=" do |value|
      value = Date.strptime(value, "%m/%d/%Y") rescue value
      write_attribute attr_name, value
    end
  end
  
  def time_writer(attr_name)
    define_method "#{attr_name}=" do |value|
      value = Time.parse(value) rescue value
      write_attribute attr_name, value
    end
  end
  
  def time_of_day_writer(attr_name)
    define_method "#{attr_name}=" do |value|
      value = TimeOfDay.parse(value) rescue value
      write_attribute attr_name, value
    end  
  end
end

ActiveRecord::Base.extend TypeCastingWriters

class FormModel
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  extend TypeCastingWriters

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
    date_writer name
    validations = validations.merge(:date => true)
    validates name, validations
  end

  def self.attr_time(name, validations={})
    attr_reader name
    time_writer name
    validations = validations.merge(:time => true)
    validates name, validations
  end

  def self.attr_time_of_day(name, validations={})
    attr_reader name
    time_of_day_writer name
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
  
  # Compatibility with ActiveRecord
  def write_attribute(attr_name, value)
    instance_variable_set "@#{attr_name}", value
  end
  
  # Compatibility with ActiveRecord
  def read_attribute_before_type_cast(attr_name)
    instance_variable_get "@#{attr_name}"
  end
end
