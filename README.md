# 🇯🇵 후쿠오카 여행 대시보드 — 2026.11.24~11.29

**처음에는 GitHub만 있으면 됩니다.** 업로드 후 바로 장소 저장·일정 작성·경비 기록·JSON 백업이 가능합니다.
두 사람이 **다른 휴대폰에서 같은 데이터를 보려면** Supabase를 추가로 연결해야 합니다.

## 어떤 파일을 GitHub에 올리나요?

1. `index.html` — 화면
2. `styles.css` — 디자인
3. `app.js` — 기능
4. `config.js` — 연결 설정 (처음에는 빈 값 그대로)

`supabase-setup.sql`과 `README.md`는 GitHub에 올려도 되지만 사이트 실행에 필요하지 않습니다. `supabase-setup.sql`은 **새 Supabase 프로젝트 SQL Editor에서 실행**하는 파일입니다.

## 1. 새 GitHub 계정 만들기

1. https://github.com/signup 에서 새 이메일로 가입합니다. 이메일 인증까지 합니다.
2. https://github.com/new 에 들어갑니다.
3. Repository name에 `fukuoka-trip` 입력합니다.
4. **Public**을 선택합니다. (무료 계정에서 GitHub Pages 기본 사용)
5. README는 GitHub에서 자동 추가하지 않아도 됩니다. **Create repository**를 누릅니다.

## 2. 만든 파일 업로드하기

1. 이 ZIP 파일을 컴퓨터에서 압축 해제합니다.
2. 새 GitHub 저장소 화면에서 **uploading an existing file** (또는 `Add file` → `Upload files`)을 누릅니다.
3. `index.html`, `styles.css`, `app.js`, `config.js` **4개 파일**을 한꺼번에 드래그합니다.
4. 아래 **Commit changes**를 누릅니다.
5. 저장소의 파일 목록에 네 파일이 보이면 성공입니다.

> 주의: ZIP 파일 그대로 업로드하면 웹사이트가 실행되지 않습니다. ZIP을 풀고 파일 4개를 올리세요.

## 3. GitHub Pages 켜기

1. 저장소 위쪽의 **Settings** → 왼쪽 **Pages**로 갑니다.
2. **Build and deployment** → Source에 **Deploy from a branch**를 선택합니다.
3. Branch에서 **main**, 폴더 **/(root)**를 선택하고 **Save**를 누릅니다.
4. Pages 화면에 표시되는 **Visit site** 또는 링크를 열어봅니다.
5. 예: `https://내아이디.github.io/fukuoka-trip/`

처음부터 작동하는 기능: 📍 장소 직접 등록 / 🗓️ 6일 일정 / 🗺️ 지도 동선 / 🧳 숙소·항공권·예약·준비물 / 💴 엔화 경비 / 📦 JSON 백업.

## 4. 장소 검색에 대한 설명

- 기본 모드는 **OpenStreetMap의 무료 Nominatim 장소 검색**입니다. 검색을 눌렀을 때만 호출되며 검색어가 한국어일 때 결과가 적을 수 있습니다. 일본어/영어로도 검색해 보세요.
- 무료 검색 제한 및 정책: https://operations.osmfoundation.org/policies/nominatim/ — 최대 초당 1회, 출처 표시, 자동완성/대량 검색 불가.
- `Google 지도에서 검색` 버튼은 항상 Google Maps를 열 수 있습니다.
- **선택 기능**: Google Maps API를 연결하면 사이트 안에서 **Google Places 검색**을 쓸 수 있습니다. Google Cloud 계정·결제 등록 및 Places API (New), Maps JavaScript API 사용 설정이 필요하고 비용이 발생할 수 있습니다.
- Google 키는 반드시 **HTTP 리퍼러 제한**을 걸어 내 GitHub Pages 주소에서만 쓰도록 합니다. 키를 config.js의 `GOOGLE_MAPS_API_KEY`에 입력합니다. Google Maps Platform의 별도 데이터 이용·보관 약관도 확인하세요.

## 5. 다른 기기·여자친구와 함께 쓰려면 (선택)

> Supabase 연결 **전**에 로컬에서 입력한 여행 데이터는 새 클라우드 방으로 자동 전송되지 않습니다. 로컬 모드의 **설정 → 백업 파일 저장**을 먼저 누른 뒤, 클라우드를 연결하고 **설정 → 백업 파일 불러오기**를 하세요.

1. https://supabase.com/ 에서 회원가입 및 로그인합니다.
2. **New project** → 프로젝트 이름을 `fukuoka-trip`으로 설정하고 데이터베이스 비밀번호를 안전하게 보관합니다. 리전은 일본/동아시아 등 가까운 위치를 선택해도 됩니다.
3. 프로젝트 화면 **SQL Editor** → **New query**를 열고 `supabase-setup.sql`의 **내용 전체**를 붙여넣어 **Run**합니다. **반드시 새 프로젝트에서만** 실행하세요.
4. **Authentication** → **Sign In / Providers** (UI 표기는 변경될 수 있음) → **Anonymous Sign-Ins**를 **Enable** 합니다.
5. **Project Settings** → **API Keys**에서 **Project URL**과 **Publishable key**를 확인합니다. 구 UI에서는 anon/public key가 있을 수 있으나 **secret/service_role 키는 사용하면 안 됩니다.**
6. GitHub 저장소의 `config.js` → 연필 모양(Edit) → 아래 두 값을 채워서 **Commit changes**를 합니다.

```js
window.FUKUOKA_CONFIG = {
  SUPABASE_URL: 'https://xxxxx.supabase.co',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_xxxxxxxxx',
  GOOGLE_MAPS_API_KEY: ''
};
```

7. GitHub Pages를 새로고침하면 **여행방 만들기** 또는 **초대코드 10자리로 참여** 화면이 나옵니다.
8. 첫 기기에서 **새 여행방 만들기** → 상단 톱니바퀴(설정)에서 **10자리 초대코드**를 확인합니다.
9. 여자친구 휴대폰에서 같은 GitHub Pages 주소 접속 → **초대코드로 참여**합니다.
10. 장소를 한 개 테스트 저장해 보고 두 기기에 같이 보이는지 확인합니다.

**중요:** 익명 로그인은 같은 브라우저에 유지됩니다. 브라우저 캐시·사이트 데이터를 지우거나 기기를 바꾸면 기존 익명 사용자 자격이 사라질 수 있습니다. **초대코드를 따로 안전하게 보관**하면 같은 방에 다시 참여할 수 있습니다. 초대코드를 아는 사람은 여행 정보를 읽고 수정할 수 있습니다. 예약번호 등 개인정보 관리에 주의하세요.

## 6. 이전 데이터가 이상해 보일 때

이 새 버전은 기존 사이트·기존 Supabase 데이터를 건드리지 않습니다. 기존 GitHub 저장소도 삭제하지 마세요.
새 버전은 별도 로컬 저장 키(`fukuoka-trip-v2-data`)를 사용합니다. 예전 데이터가 자동으로 합쳐지지 않습니다.

- 장소를 새로 추가하세요.
- 저장된 정보는 **설정 → 백업 파일 저장**을 통해 JSON으로 보관하세요.
- 다른 브라우저에서 같은 GitHub Pages 주소를 열어도 개인용 모드 데이터는 자동으로 옮겨지지 않습니다.
- 클라우드 연결을 설정했다면 10자리 초대코드로 같은 방에 들어가세요.

## 보안·기술 메모

- Supabase에서 실제 저장되는 정보는 클라우드 여행방의 JSON 데이터이며, 공유 변경 시 **버전 비교 방식**을 사용해 동시에 수정하는 경우 덮어쓰기를 줄입니다.
- 초대코드는 사적인 그룹 공유를 위한 것이며 별도 계정 암호나 강력한 인증을 대체하지 않습니다.
- Google API 키는 클라이언트에 공개되므로 반드시 리퍼러/API 제한을 사용합니다. Supabase 비밀 키는 절대로 브라우저 코드에 올리지 않습니다.
- 개인용 로컬 데이터는 사이트 origin별 localStorage에 저장됩니다. 브라우저 데이터 삭제나 기기 분실 시 데이터가 사라질 수 있으니 자주 JSON 백업하세요.
- 저장소를 Public으로 만들면 코드가 공개됩니다. 개인정보는 코드나 README에 직접 넣지 말고 앱에 입력하세요.
