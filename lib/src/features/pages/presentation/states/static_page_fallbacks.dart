class StaticPageFallback {
  const StaticPageFallback({
    required this.slug,
    required this.title,
    required this.content,
    this.summary,
  });

  final String slug;
  final String title;
  final String content;
  final String? summary;
}

const staticPageFallbacks = <String, StaticPageFallback>{
  've-chung-toi': StaticPageFallback(
    slug: 've-chung-toi',
    title: 'Về chúng tôi',
    summary: 'Câu chuyện thương hiệu, giá trị cốt lõi và hệ thống chi nhánh.',
    content:
        'La Douceur là tiệm bánh thủ công tại TP.HCM. Chúng tôi tập trung vào nguyên liệu chất lượng, quy trình làm bánh kỹ lưỡng và trải nghiệm khách hàng thân thiện.',
  ),
  'thanh-vien': StaticPageFallback(
    slug: 'thanh-vien',
    title: 'Thành viên',
    summary: 'Hạng thành viên, quyền lợi, cách tích điểm và đổi ưu đãi.',
    content:
        'Tham gia chương trình thành viên La Douceur để tích điểm, thăng hạng Silver - Gold - Platinum và nhận ưu đãi độc quyền.',
  ),
  'store': StaticPageFallback(
    slug: 'store',
    title: 'Cửa hàng',
    summary: 'Địa chỉ, giờ mở cửa và thông tin liên hệ cửa hàng.',
    content:
        'Ghé cửa hàng để trải nghiệm bánh tươi mỗi ngày. Chúng tôi luôn sẵn sàng hỗ trợ tư vấn sản phẩm và nhận đặt bánh theo yêu cầu.',
  ),
  'chinh-sach-bao-mat': StaticPageFallback(
    slug: 'chinh-sach-bao-mat',
    title: 'Chính sách bảo mật',
    summary: 'Quy định thu thập, sử dụng và bảo vệ dữ liệu cá nhân.',
    content:
        'Chúng tôi thu thập thông tin cần thiết để xử lý đơn hàng và chăm sóc khách hàng. Dữ liệu cá nhân được bảo mật và chỉ chia sẻ cho đối tác liên quan khi cần.',
  ),
  'chinh-sach-giao-hang': StaticPageFallback(
    slug: 'chinh-sach-giao-hang',
    title: 'Chính sách giao hàng',
    summary: 'Khu vực giao, thời gian dự kiến và phí vận chuyển.',
    content:
        'La Douceur hỗ trợ giao hàng tại TP.HCM và một số khu vực lân cận. Thời gian và phí giao hàng phụ thuộc địa bàn và thời điểm đặt đơn.',
  ),
  'chinh-sach-doi-tra': StaticPageFallback(
    slug: 'chinh-sach-doi-tra',
    title: 'Chính sách đổi trả',
    summary: 'Điều kiện đổi trả, quy trình xử lý và hình thức bồi hoàn.',
    content:
        'Khách hàng có thể yêu cầu đổi trả nếu sản phẩm lỗi chất lượng, sai đơn hoặc hư hỏng trong vận chuyển. Vui lòng liên hệ sớm kèm hình ảnh đơn hàng để được hỗ trợ.',
  ),
  'dieu-khoan-su-dung': StaticPageFallback(
    slug: 'dieu-khoan-su-dung',
    title: 'Điều khoản sử dụng',
    summary: 'Quy định tài khoản, đặt hàng, thanh toán và trách nhiệm pháp lý.',
    content:
        'Khi sử dụng dịch vụ trên website/app, bạn đồng ý với điều khoản về tài khoản, đặt hàng, thanh toán, sở hữu trí tuệ và các quy định liên quan.',
  ),
  'cua-hang': StaticPageFallback(
    slug: 'cua-hang',
    title: 'Cửa hàng',
    summary: 'Địa chỉ, giờ mở cửa và thông tin liên hệ cửa hàng.',
    content:
        'Ghé cửa hàng để trải nghiệm bánh tươi mỗi ngày. Chúng tôi luôn sẵn sàng hỗ trợ tư vấn sản phẩm và nhận đặt bánh theo yêu cầu.',
  ),
};

const staticPageOrder = <String>[
  've-chung-toi',
  'thanh-vien',
  'store',
  'chinh-sach-bao-mat',
  'chinh-sach-giao-hang',
  'chinh-sach-doi-tra',
  'dieu-khoan-su-dung',
];
