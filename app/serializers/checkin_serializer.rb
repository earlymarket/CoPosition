class CheckinSerializer < ActiveModel::Serializer
  FILTERED_SET = %i(
    id
    device_id
    lat
    lng
    address
    city
    postal_code
    country_code
    created_at
    updated_at
  )

  attributes *FILTERED_SET

  def attributes(*args)
    h = super

    (object.attribute_names.map(&:to_sym) - FILTERED_SET).each do |key|
      h[key] = object.attributes[key]
    end

    h
  end
end
