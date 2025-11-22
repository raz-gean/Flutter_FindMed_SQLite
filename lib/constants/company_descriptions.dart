/// Centralized short descriptions for known pharmacy companies.
/// Extend this map as new companies are added.
const Map<String, String> kCompanyDescriptions = {
  'Mercury Drug':
      'Widely trusted Philippine pharmacy chain offering a broad selection of branded and generic medicines, health essentials, and reliable customer service.',
  'Rose Pharmacy':
      'Community-focused pharmacy known for approachable service, personal care items, and accessible everyday health solutions.',
  'Generika Drugstore':
      'Advocate of affordable, high-quality generic medicines helping make treatment more cost-effective for families.',
  'The Generics Pharmacy':
      'Nationwide provider specializing in quality generic pharmaceuticals with value pricing and wide branch coverage.',
};

/// Helper to retrieve a description or a fallback message.
String companyDescription(String name) =>
    kCompanyDescriptions[name] ?? 'Details unavailable.';
