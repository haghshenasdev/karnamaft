import 'category_model.dart';

class CategoryRepository {
  CategoryRepository._();

  static List<CategoryModel> get categories => _categories;

  static List<CategoryModel> get topCategories {
    final result = <CategoryModel>[];

    void walk(List<CategoryModel> list) {
      for (final item in list) {
        result.add(item);
        walk(item.children);
      }
    }

    walk(_categories);

    result.sort((a, b) => b.useCount.compareTo(a.useCount));

    return result.take(8).toList();
  }

  static List<CategoryModel> search(String keyword) {
    if (keyword.trim().isEmpty) {
      return _categories;
    }

    final text = keyword.trim().toLowerCase();

    List<CategoryModel> filter(List<CategoryModel> source) {
      final List<CategoryModel> result = [];

      for (final item in source) {
        final children = filter(item.children);

        if (item.title.toLowerCase().contains(text) || children.isNotEmpty) {
          result.add(item.copyWith(children: children));
        }
      }

      return result;
    }

    return filter(_categories);
  }

  //--------------------------------------------------------
  // Sample Data
  //--------------------------------------------------------

  static final List<CategoryModel> _categories = [
    CategoryModel(
      id: "1",
      title: "شخصی",
      icon: "person",
      useCount: 95,
      children: [
        CategoryModel(
          id: "11",
          title: "خانه",
          parentId: "1",
          icon: "home",
          useCount: 70,
        ),
        CategoryModel(
          id: "12",
          title: "خرید",
          parentId: "1",
          icon: "shopping",
          useCount: 60,
        ),
        CategoryModel(
          id: "13",
          title: "سلامتی",
          parentId: "1",
          icon: "favorite",
          useCount: 40,
          children: [
            CategoryModel(
              id: "131",
              title: "دارو",
              parentId: "13",
              icon: "medical",
              useCount: 18,
            ),
            CategoryModel(
              id: "132",
              title: "ورزش",
              parentId: "13",
              icon: "fitness",
              useCount: 22,
            ),
          ],
        ),
      ],
    ),

    CategoryModel(
      id: "2",
      title: "کاری",
      icon: "work",
      useCount: 90,
      children: [
        CategoryModel(
          id: "21",
          title: "جلسات",
          parentId: "2",
          icon: "meeting",
          useCount: 45,
        ),
        CategoryModel(
          id: "22",
          title: "مشتریان",
          parentId: "2",
          icon: "group",
          useCount: 37,
        ),
        CategoryModel(
          id: "23",
          title: "پروژه‌ها",
          parentId: "2",
          icon: "folder",
          useCount: 65,
          children: [
            CategoryModel(
              id: "231",
              title: "لاراول",
              parentId: "23",
              icon: "code",
              useCount: 24,
            ),
            CategoryModel(
              id: "232",
              title: "فلاتر",
              parentId: "23",
              icon: "phone",
              useCount: 39,
            ),
            CategoryModel(
              id: "233",
              title: "فیلامنت",
              parentId: "23",
              icon: "dashboard",
              useCount: 14,
            ),
          ],
        ),
      ],
    ),

    CategoryModel(
      id: "3",
      title: "آموزشی",
      icon: "school",
      useCount: 82,
      children: [
        CategoryModel(
          id: "31",
          title: "دانشگاه",
          parentId: "3",
          icon: "school",
          useCount: 50,
        ),
        CategoryModel(
          id: "32",
          title: "کتاب",
          parentId: "3",
          icon: "book",
          useCount: 32,
        ),
        CategoryModel(
          id: "33",
          title: "آزمون",
          parentId: "3",
          icon: "quiz",
          useCount: 15,
        ),
      ],
    ),

    CategoryModel(
      id: "4",
      title: "مالی",
      icon: "wallet",
      useCount: 73,
      children: [
        CategoryModel(
          id: "41",
          title: "درآمد",
          parentId: "4",
          icon: "money",
          useCount: 41,
        ),
        CategoryModel(
          id: "42",
          title: "هزینه",
          parentId: "4",
          icon: "payment",
          useCount: 57,
        ),
        CategoryModel(
          id: "43",
          title: "بانک",
          parentId: "4",
          icon: "account_balance",
          useCount: 26,
        ),
      ],
    ),

    CategoryModel(
      id: "5",
      title: "خانواده",
      icon: "family",
      useCount: 64,
      children: [
        CategoryModel(
          id: "51",
          title: "پدر",
          parentId: "5",
          icon: "person",
          useCount: 12,
        ),
        CategoryModel(
          id: "52",
          title: "مادر",
          parentId: "5",
          icon: "person",
          useCount: 14,
        ),
        CategoryModel(
          id: "53",
          title: "فرزندان",
          parentId: "5",
          icon: "child",
          useCount: 18,
        ),
      ],
    ),

    CategoryModel(
      id: "6",
      title: "سفر",
      icon: "travel",
      useCount: 48,
      children: [
        CategoryModel(
          id: "61",
          title: "داخلی",
          parentId: "6",
          icon: "map",
          useCount: 18,
        ),
        CategoryModel(
          id: "62",
          title: "خارجی",
          parentId: "6",
          icon: "flight",
          useCount: 10,
        ),
        CategoryModel(
          id: "63",
          title: "هتل",
          parentId: "6",
          icon: "hotel",
          useCount: 20,
        ),
      ],
    ),

    CategoryModel(
      id: "7",
      title: "سرگرمی",
      icon: "movie",
      useCount: 42,
      children: [
        CategoryModel(
          id: "71",
          title: "فیلم",
          parentId: "7",
          icon: "movie",
          useCount: 20,
        ),
        CategoryModel(
          id: "72",
          title: "موسیقی",
          parentId: "7",
          icon: "music",
          useCount: 18,
        ),
        CategoryModel(
          id: "73",
          title: "بازی",
          parentId: "7",
          icon: "games",
          useCount: 15,
        ),
      ],
    ),
  ];
}
