# इन files को GitHub पर डालने की हिंदी गाइड

सच बात पहले: **मैं आपके GitHub पर ख़ुद upload नहीं कर सकता।** पूरी जाँच के बाद
कारण पक्का पता चल गया है:

- इस environment का GitHub token एक **GitHub App token** है (`ghu_` prefix)।
- उस App की आपके account पर **0 installations** हैं। जाँच का नतीजा:
  `https://api.github.com/user/installations` → `total_count: 0`
- इसलिए GitHub उसे सिर्फ़ **पढ़ने** देता है, **लिखने नहीं**। हर लिखने वाला
  रास्ता 403 देता है: `git push`, Contents API, gist — सब।

यानी upload आपको ख़ुद करना होगा। दो आसान तरीके नीचे हैं।

---

## तरीका 0 (सबसे छोटा): App को repo का access दें, फिर मैं push कर दूँगा

1. फ़ोन में `github.com` खोलें → अपनी photo → **Settings**।
2. बाईं तरफ़ नीचे **Applications** → **Installed GitHub Apps**।
3. जो **OpenHands** वाला App दिखे, उसके आगे **Configure** दबाएँ।
4. **Repository access** में **Only select repositories** चुनें और
   `ue5-android-apk` को add करें।
5. **Save** दबाएँ। मुझे बताएँ — मैं तुरंत push कर दूँगा।

(अगर Installed GitHub Apps में OpenHands न दिखे, तो नीचे तरीका 1 इस्तेमाल करें।)

---

## तरीका 1 (हमेशा चलेगा): Personal Access Token से ख़ुद push करें

### चरण A — GitHub पर खाली repo बनाएँ (फ़ोन के browser से)

1. फ़ोन में Chrome खोलें → `github.com` पर जाएँ → sign in करें।
2. ऊपर दाईं तरफ़ **+** icon → **New repository**।
3. **Repository name:** `ue5-android-apk`
4. **Public** चुनें।
5. **"Add a README file" पर tick न करें** (हमारे पास पहले से README है)।
6. **Create repository** दबाएँ।

### चरण B — एक Personal Access Token बनाएँ (push के लिए ज़रूरी)

1. GitHub में: ऊपर दाईं तरफ़ अपनी photo → **Settings**।
2. नीचे **Developer settings** → **Personal access tokens** → **Tokens (classic)**।
3. **Generate new token (classic)** दबाएँ।
4. Note: `ue5 push`, Expiration: 7 days, और **`repo`** वाले box पर tick लगाएँ।
5. **Generate token** दबाएँ।
6. जो token दिखे (जैसे `ghp_xxxx...`) उसे **copy करके कहीं safe रख लें** —
   यह दोबारा नहीं दिखेगा।

### चरण C — VM के terminal से push करें

(यही VM आप build के लिए भी इस्तेमाल करेंगे। VM का SSH terminal खोलें।)

```bash
wget -O p.tar.gz https://work-1-zjjcvxvizlfoshgx.prod-runtime.all-hands.dev/ue5-android-apk.tar.gz
tar xzf p.tar.gz && cd ue5-android-apk
./scripts/push_to_github.sh https://github.com/<आपका-नाम>/ue5-android-apk.git
```

जब **password** पूछे → वो `ghp_...` token paste करें (GitHub password नहीं)।

या बिना script के, सीधे:

```bash
wget -O p.tar.gz https://work-1-zjjcvxvizlfoshgx.prod-runtime.all-hands.dev/ue5-android-apk.tar.gz
tar xzf p.tar.gz && cd ue5-android-apk
git init -b main
git add -A
git commit -m "UE5 -> Android APK pipeline"
git remote add origin https://github.com/<आपका-नाम>/ue5-android-apk.git
git push -u origin main
```

बस! अब आपका repo इस पते पर live होगा:
`https://github.com/<आपका-नाम>/ue5-android-apk`

---

## तरीका 2 (terminal से ही, gh CLI के साथ)

अगर VM पर `gh` install है, तो सब एक command में:

```bash
gh auth login          # device code से login करें (browser में code डालें)
wget -O p.tar.gz https://work-1-zjjcvxvizlfoshgx.prod-runtime.all-hands.dev/ue5-android-apk.tar.gz
tar xzf p.tar.gz && cd ue5-android-apk
git init -b main && git add -A && git commit -m "UE5 -> Android APK pipeline"
gh repo create ue5-android-apk --public --source=. --push
```

---

## तरीका 3 (बिलकुल बिना terminal): browser से files upload करें

अगर आप GitHub website से ही upload करना चाहें:

1. फ़ोन में repo खोलें → **Add file** → **Upload files**।
2. अपने फ़ोन में `ue5-android-apk.tar.gz` **पहले extract** करना पड़ेगा (किसी
   file manager app से)। Extract करने पर `ue5-android-apk` folder मिलेगा।
3. उस folder की सारी files/folders को upload box में **drag** करें।
4. नीचे **Commit changes** दबाएँ।

नोट: फ़ोन पर nested folders upload करना थोड़ा झंझट भरा होता है, और यह तरीका
चरण C की तुलना में धीमा है। इसलिए **तरीका 1 सबसे अच्छा है।**

---

## मदद

- **push करते समय "Authentication failed"** → password की जगह Personal Access
  Token (चरण B) paste करें, GitHub का login password नहीं।
- **"Repository not found"** → remote URL में अपना सही username डालें। जाँचें:
  `git remote -v`
- **token कहाँ से बनाएँ, समझ नहीं आया** → बताएँ, मैं step-by-step और detail में
  लिख दूँगा।
- **चाहते हैं कि सिर्फ़ मैं करूँ** → मेरे पास जो token है उसमें repo बनाने की
  permission नहीं है, इसलिए तकनीकी रूप से मुमकिन नहीं। पर आप चरण A कर दें और
  मुझे repo का link दें, तो मैं बाकी commands आपके लिए exact बना दूँगा।
