# frozen_string_literal: true

customers = [
  { name: "María García", email: "maria@example.com", address: "Calle Principal 123, CDMX" },
  { name: "Carlos López", email: "carlos@example.com", address: "Av. Reforma 456, Guadalajara" },
  { name: "Ana Martínez", email: "ana@example.com", address: "Blvd. Constitución 789, Monterrey" },
  { name: "Juan Hernández", email: "juan@example.com", address: "Calle 5 de Mayo 321, Puebla" },
  { name: "Laura Sánchez", email: "laura@example.com", address: "Av. Juárez 654, Querétaro" }
]

customers.each do |attrs|
  Customer.find_or_create_by!(email: attrs[:email]) do |customer|
    customer.assign_attributes(attrs)
  end
end

puts "Created #{Customer.count} customers"
