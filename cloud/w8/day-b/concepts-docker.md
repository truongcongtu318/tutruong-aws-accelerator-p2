# Docker / Container Concepts

## 1. Container là gì?

**Container** là một môi trường chạy ứng dụng được đóng gói cùng với dependencies cần thiết.

Một container thường chứa:

- Application code
- Runtime: Node.js, Python, Java, Go...
- Libraries/dependencies
- Environment variables
- File system tối thiểu để app chạy

Container giúp app chạy ổn định ở nhiều môi trường:

```text
Laptop developer
CI/CD runner
Staging server
Production server
```

Nếu image giống nhau thì container chạy ra cũng giống nhau.

---

## 2. Container khác VM thế nào?

| Tiêu chí | Virtual Machine | Container |
|---|---|---|
| Có OS riêng | Có | Không, dùng chung kernel host |
| Kích thước | Lớn, thường GB | Nhỏ hơn, thường MB |
| Khởi động | Chậm hơn | Nhanh hơn |
| Isolation | Mạnh hơn | Nhẹ hơn |
| Use case | Chạy full OS | Đóng gói app/service |

Mô hình VM:

```text
Hardware
  └── Host OS
      └── Hypervisor
          ├── Guest OS + App A
          └── Guest OS + App B
```

Mô hình Container:

```text
Hardware
  └── Host OS
      └── Container Runtime
          ├── Container A: App A + deps
          └── Container B: App B + deps
```

---

## 3. Docker là gì?

**Docker** là platform giúp build, run và quản lý container.

Docker gồm các thành phần chính:

| Thành phần | Ý nghĩa |
|---|---|
| Dockerfile | Công thức build image |
| Image | Template read-only để tạo container |
| Container | Instance đang chạy từ image |
| Registry | Nơi lưu image, ví dụ Docker Hub, ECR |
| Docker Engine | Runtime chạy container |

---

## 4. Image là gì?

**Image** là package read-only chứa app và dependencies.

Ví dụ image:

```text
nginx:latest
node:20-alpine
python:3.12-slim
ubuntu:24.04
```

Image được build từ Dockerfile.

```text
Dockerfile → docker build → Image → docker run → Container
```

---

## 5. Container là gì?

**Container** là một process đang chạy từ image.

Một image có thể tạo nhiều container:

```text
nginx image
  ├── nginx container 1
  ├── nginx container 2
  └── nginx container 3
```

---

## 6. Dockerfile cơ bản

Ví dụ Dockerfile cho Node.js app:

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

Ý nghĩa:

| Instruction | Ý nghĩa |
|---|---|
| `FROM` | Base image |
| `WORKDIR` | Thư mục làm việc trong container |
| `COPY` | Copy file từ host vào image |
| `RUN` | Chạy command khi build image |
| `EXPOSE` | Document port app dùng |
| `CMD` | Command mặc định khi container chạy |

---

## 7. Build image

```bash
docker build -t my-app:1.0 .
```

Ý nghĩa:

```text
-t my-app:1.0    đặt tên image là my-app, tag là 1.0
.                build context là thư mục hiện tại
```

Kiểm tra image:

```bash
docker images
```

---

## 8. Run container

```bash
docker run -d --name my-app -p 8080:3000 my-app:1.0
```

Ý nghĩa:

| Flag | Ý nghĩa |
|---|---|
| `-d` | Chạy detached/background |
| `--name` | Đặt tên container |
| `-p 8080:3000` | Map port host 8080 tới container 3000 |

Port mapping:

```text
Browser localhost:8080
        ↓
Host port 8080
        ↓
Container port 3000
        ↓
App inside container
```

---

## 9. Volume

Container filesystem thường ephemeral — container bị xoá thì data trong container cũng mất.

Volume giúp lưu data bên ngoài container.

Ví dụ:

```bash
docker run -v my-data:/data nginx
```

Bind mount thư mục local:

```bash
docker run -v ./app:/app node:20-alpine
```

---

## 10. Network cơ bản

Container có network riêng. Muốn truy cập từ host cần port mapping:

```bash
docker run -p 8080:80 nginx
```

Container gọi nhau trong cùng Docker network bằng tên container/service.

---

## 11. Các lệnh Docker cần nhớ

```bash
# Xem container đang chạy
docker ps

# Xem tất cả container
docker ps -a

# Xem image
docker images

# Build image
docker build -t my-app:1.0 .

# Run container
docker run -d --name my-app -p 8080:3000 my-app:1.0

# Xem logs
docker logs my-app

# Vào container
docker exec -it my-app sh

# Stop container
docker stop my-app

# Remove container
docker rm my-app

# Remove image
docker rmi my-app:1.0
```

---

## 12. Best practices Dockerfile

Nên:

- Dùng base image nhỏ như `alpine`, `slim`
- Copy dependency file trước để tận dụng build cache
- Không chạy app bằng root user nếu production
- Không copy file thừa vào image
- Dùng `.dockerignore`
- Pin version image, tránh `latest` trong production

Không nên:

- Copy toàn bộ repo nếu không cần
- Đưa secret vào image
- Hard-code credential trong Dockerfile
- Build image quá lớn

---

## 13. Mini quiz

1. Container khác VM ở điểm nào?
2. Image khác container ở điểm nào?
3. Dockerfile dùng để làm gì?
4. `docker build` khác `docker run` thế nào?
5. `-p 8080:3000` nghĩa là gì?
6. Vì sao cần volume?
7. Vì sao không nên đưa secret vào Dockerfile?
