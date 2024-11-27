class Food {
  final int id;
  final String name;
  final String image;
  final String estimatedSpoilage;
  final String details;
  final String description;
  final String storageTemperature;
  final String shelfLife;
  final List<String> signsOfSpoilage;

  Food({
    required this.id,
    required this.name,
    required this.image,
    required this.estimatedSpoilage,
    required this.details,
    required this.description,
    required this.storageTemperature,
    required this.shelfLife,
    required this.signsOfSpoilage,
  });
}

final List<Food> foods = [
  Food(
    id: 1,
    name: "Adobo",
    image: "assets/adobo.jpg",
    estimatedSpoilage: "4-6 Days",
    details: "Store at 40°F (4°C). Signs: Sour smell, oil separation.",
    description:
        "A classic Filipino dish made with marinated pork or chicken, soy sauce, vinegar, garlic, and spices. A hearty meal often served with rice.",
    storageTemperature:
        "Ensure Adobo is stored at temperatures below 40°F (4°C). Keep refrigerated to prevent spoilage.",
    shelfLife:
        "Consume within 3-4 days when stored in the fridge. Freezing can extend its shelf life but may alter texture slightly.",
    signsOfSpoilage: [
      "Sour or fermented smell",
      "Oil separation with cloudy or thick appearance",
      "Mold growth",
    ],
  ),
  Food(
    id: 2,
    name: "Menudo",
    image: "assets/menudo.jpg",
    estimatedSpoilage: "3-5 Days",
    details: "Store at 40°F (4°C). Signs: Sour smell, mold.",
    description:
        "A savory Filipino stew made from pork, beef tripe, and a rich tomato-based sauce. A beloved dish often enjoyed with steamed rice.",
    storageTemperature:
        "Ensure Menudo is stored at temperatures below 40°F (4°C) when refrigerated. Higher temperatures can accelerate spoilage.",
    shelfLife:
        "Consume Menudo within 2-3 days if stored in the fridge. For longer storage, freezing is an option, but the quality may decrease over time.",
    signsOfSpoilage: [
      "Sour or off smell",
      "Discoloration or slimy texture on the meat",
      "Excessive bubbling or froth (indicating fermentation)",
      "Mold growth",
    ],
  ),
  Food(
    id: 3,
    name: "Mechado",
    image: "assets/mechado.jpg",
    estimatedSpoilage: "2-4 Days",
    details: "Store at 40°F (4°C). Signs: Discoloration, sour smell.",
    description:
        "A flavorful Filipino dish made with beef, lard, tomato sauce, and vegetables. Often served during family gatherings or special occasions.",
    storageTemperature:
        "Ensure Mechado is stored below 40°F (4°C). Avoid leaving it out for extended periods to maintain its quality.",
    shelfLife:
        "Consume within 2-3 days if stored in the refrigerator. For longer storage, freezing is ideal but can affect texture.",
    signsOfSpoilage: [
      "Sour smell",
      "Slimy or sticky texture",
      "Mold spots",
    ],
  ),
];
