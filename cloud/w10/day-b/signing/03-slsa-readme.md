# SlSA Supply Chain Levels minh hoạ — Cấu trúc thư mục và documentation
# Đây không phải manifest K8s, mà là tài liệu theo dõi mức độ trưởng thành
# của chuỗi cung ứng phần mềm theo tiêu chuẩn SLSA

Mô tả:
W10 hướng tới đạt được SLSA Level 2-3:
- Level 1: CI pipeline build và scan image tự động ✓
- Level 2: Image được ký (signed) bằng key riêng ✓
- Level 3: Image verifiable provenance + threat model (đang tiến tới)

## Exception ADR Template
Khi cần bỏ qua một CVE, ghi lại ADR tại file này với cấu trúc:

```
# ADR-YYYYMMDD-001: Exception CVE-XXXX-YYYY
## Ngày tạo: 2026-06-16
## Loại: CVE Exception
## Mô tả:
CVE-XXXX-YYYY phát hiện trong thư viện libfoo 1.2.3.
Lý do: library không được sử dụng trong runtime (dev dependency).
Expiration: 2026-07-16
## Người duyệt: [Tên]
```
