class StaticPageFallback {
  const StaticPageFallback({
    required this.slug,
    required this.title,
    required this.content,
  });

  final String slug;
  final String title;
  final String content;
}

const staticPageFallbacks = <String, StaticPageFallback>{
  've-chung-toi': StaticPageFallback(
    slug: 've-chung-toi',
    title: 'Ve chung toi',
    content:
        'La Douceur la tiem banh thu cong tai TP.HCM. Chung toi tap trung vao nguyen lieu chat luong, quy trinh lam banh ky luong va trai nghiem khach hang than thien.',
  ),
  'chinh-sach-bao-mat': StaticPageFallback(
    slug: 'chinh-sach-bao-mat',
    title: 'Chinh sach bao mat',
    content:
        'Chung toi thu thap thong tin can thiet de xu ly don hang va cham soc khach hang. Du lieu ca nhan duoc bao mat, khong ban cho ben thu ba va chi chia se voi doi tac van chuyen/thanh toan khi can.',
  ),
  'chinh-sach-giao-hang': StaticPageFallback(
    slug: 'chinh-sach-giao-hang',
    title: 'Chinh sach giao hang',
    content:
        'La Douceur ho tro giao hang tai TP.HCM va mot so khu vuc lan can. Thoi gian va phi giao hang phu thuoc dia ban va thoi diem dat don.',
  ),
  'chinh-sach-doi-tra': StaticPageFallback(
    slug: 'chinh-sach-doi-tra',
    title: 'Chinh sach doi tra',
    content:
        'Khach hang co the yeu cau doi/tra neu san pham loi chat luong, sai don hoac hu hong trong van chuyen. Vui long lien he som va cung cap hinh anh don hang de duoc ho tro.',
  ),
  'dieu-khoan-su-dung': StaticPageFallback(
    slug: 'dieu-khoan-su-dung',
    title: 'Dieu khoan su dung',
    content:
        'Khi su dung dich vu tren website/app, ban dong y voi dieu khoan ve tai khoan, dat hang, thanh toan, so huu tri tue va cac quy dinh lien quan.',
  ),
};

const staticPageOrder = <String>[
  've-chung-toi',
  'chinh-sach-bao-mat',
  'chinh-sach-giao-hang',
  'chinh-sach-doi-tra',
  'dieu-khoan-su-dung',
];
