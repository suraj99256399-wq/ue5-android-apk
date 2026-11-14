# Unreal Engine 5 Android APK — पूरी हिंदी गाइड (सिर्फ़ फ़ोन से)

यह गाइड उस इंसान के लिए है जिसके पास सिर्फ़ एक Android फ़ोन है और जिसे
Unreal Engine 5 का असली APK चाहिए। इसमें कोई PC नहीं चाहिए। सारा काम आपके
फ़ोन के browser से होगा।

---

## सबसे पहले: सच्ची बात (यह पढ़ लेना ज़रूरी है)

1. **आपका फ़ोन ख़ुद Unreal Engine build नहीं कर सकता।** Unreal के build tools
   (UnrealBuildTool, clang compiler, Android NDK) सिर्फ़ x86-64 Linux पर चलते
   हैं। Android फ़ोन ARM पर चलते हैं। यह Epic का design है — इसलिए यह
   किसी भी ऐप से नहीं बदला जा सकता।

2. **इसलिए एक Linux machine चाहिए।** अच्छी ख़बर: वह मुफ़्त मिलती है और उसे आप
   अपने फ़ोन के browser से पूरी तरह चला सकते हैं। उसे "cloud VM" कहते हैं।

3. **समय:** पूरा काम 3 से 6 घंटे लेता है (ज़्यादातर समय engine compile में
   लगता है)। आपको बैठकर इंतज़ार नहीं करना — काम चलता रहता है, बीच में
   connection टूट जाए तो वहीं से resume हो जाता है।

4. **खर्च:** नीचे दिया तरीका मुफ़्त trial credit से चलता है। पूरा काम पूरा होने
   के बाद VM बंद कर देना ज़रूरी है, वरना credit खर्च होता रहेगा।

5. **APK फ़ोन पर डालना सिर्फ़ आप कर सकते हैं।** कोई भी बाहरी मशीन आपके फ़ोन
   पर अपने आप install नहीं कर सकती। नीचे भाग 5 में आसान तरीका दिया है।

---

## भाग 1: Google Cloud पर मुफ़्त account बनाएँ

1. फ़ोन में Chrome (या कोई भी browser) खोलें।
2. `cloud.google.com/free` पर जाएँ।
3. "Start free" / "Get started for free" दबाएँ।
4. Google account से sign in करें।
5. Country: India चुनें। कार्ड की जानकारी माँगेगा (verify के लिए ₹0–₹15
   hold हो सकता है, बाद में वापस आ जाता है)। Trial में $300 का credit मिलता है,
   90 दिन के लिए।
6. "Activate" दबाएँ। अब Console खुल जाएगा।

अगर कार्ड नहीं है: Azure भी यही सुविधा देता है ($200 credit)। तरीका बिलकुल
वही है, बस नाम बदल जाते हैं।

---

## भाग 2: VM (Linux machine) बनाएँ

Console में ऊपर search box में "Compute Engine" लिखें और उसे खोलें।

1. "Create instance" दबाएँ।
2. **Name:** `ue5-build` (कुछ भी लिख सकते हैं)।
3. **Region:** कोई भी पास वाला चुनें, जैसे `asia-south1` (Mumbai)।
4. **Machine type:** "General purpose" → `e2-standard-8` चुनें
   (8 CPU, 32 GB RAM)। अगर `e2-standard-8` न दिखे तो `e2-standard-4`
   चुनें (4 CPU, 16 GB) — थोड़ा धीमा चलेगा पर काम हो जाएगा।
5. **Boot disk:** "Change" दबाएँ →
   - Operating system: **Ubuntu**
   - Version: **Ubuntu 22.04 LTS**
   - Size: **250 GB** (डिफ़ॉल्ट 10 GB से बढ़ाना ज़रूरी है)
6. **Firewall:** "Allow HTTP traffic" पर tick लगाएँ (यह APK download के लिए
   मदद करेगा)।
7. नीचे "Create" दबाएँ।

एक-दो मिनट में VM तैयार हो जाएगी।

---

## भाग 3: VM से जुड़ें (फ़ोन के browser से)

1. Compute Engine → VM instances की list में अपनी VM के आगे **SSH** बटन दबाएँ।
2. एक नई विंडो में terminal (काली स्क्रीन) खुल जाएगी। यहीं सारे command चलाने हैं।
3. यह terminal आपके फ़ोन के browser में ही चल रहा है — कोई app नहीं चाहिए।

---

## भाग 4: Build चलाएँ (कुल 3 command)

SSH terminal में एक-एक करके ये चलाएँ:

**Command 1 — code लाएँ:**

```bash
git clone <REPO_LINK> ue5-apk && cd ue5-apk
```

`<REPO_LINK>` की जगह वह लिंक डालें जो आपको नीचे "REPO" वाले हिस्से में दिया
गया है। अगर आपके पास सिर्फ़ tar.gz फ़ाइल है, तो:

```bash
wget -O ue5-android-apk.tar.gz <TARBALL_LINK> && tar xzf ue5-android-apk.tar.gz && cd ue5-android-apk
```

**Command 2 — पूरा build चलाएँ:**

```bash
./scripts/bootstrap_cloud_vm.sh
```

बस। यह script ख़ुद:
- ज़रूरी packages install करेगी,
- UE5 engine download करेगी (~38 GB),
- Android toolchain सेट करेगी,
- आपके Snapdragon 8 Gen 4 / Adreno 825 का patch लगाएगी,
- engine compile करेगी (सबसे लंबा step),
- `MyGame.apk` बनाएगी,
- और आख़िर में बताएगी कि APK फ़ोन पर कैसे लाना है।

**अगर बीच में connection टूट जाए या terminal बंद हो जाए:** घबराएँ नहीं।
SSH दोबारा खोलें, `cd ue5-apk` करें, और वही Command 2 फिर चलाएँ। काम वहीं से
आगे बढ़ेगा, शुरू से नहीं।

---

## भाग 5: APK को फ़ोन पर लाएँ

Build ख़त्म होने पर script आपको APK का पूरा path दिखाएगी। दो तरीके हैं:

**तरीका A (सबसे आसान, कोई firewall नहीं चाहिए):**
1. SSH वाली window में ऊपर दाईं तरफ़ **gear (⚙) icon** दबाएँ।
2. **Download file** चुनें।
3. वह path paste करें जो script ने दिखाया, जैसे:
   `/root/ue5-apk/MyGame/Saved/StagedBuilds/Android_ASTC/MyGame.apk`
4. Download शुरू हो जाएगा। यह फ़ाइल फ़ोन में आ जाएगी।

**तरीका B (network से):**
1. Build के बाद script एक address दिखाएगी, जैसे `http://34.x.x.x/MyGame.apk`।
2. वह address फ़ोन के browser में खोलें।
3. APK download हो जाएगी।

---

## भाग 6: APK install करें

1. फ़ोन की Settings → Apps → Special access → **Install unknown apps** में
   उस browser (जैसे Chrome) को **Allow** करें।
2. फ़ाइल Manager खोलें → Downloads → `MyGame.apk` पर tap करें।
3. "Install" दबाएँ। कुछ देर बाद ऐप install हो जाएगा।
4. ऐप खोलें। स्क्रीन के बाईं आधी तरफ़ चलने के लिए, दाईं तरफ़ घुमाने (look)
   के लिए touch करें।

---

## भाग 7: काम ख़त्म — VM बंद करें

बहुत ज़रूरी: credit बचाने के लिए VM को **Stop** या **Delete** कर दें।

1. Compute Engine → VM instances।
2. अपनी VM के आगे ⋮ (तीन बिंदु) दबाएँ।
3. **Delete** चुनें और पुष्टि करें। (APK तो आपके फ़ोन में आ चुका है, VM की
   अब ज़रूरत नहीं।)

---

## समस्या हल (कुछ आम दिक्कतें)

- **"disk full" या "No space left"** — VM की disk 250 GB से कम है। VM delete
  करके 250 GB disk वाली नई VM बनाएँ।
- **build बहुत धीमा** — 4 CPU वाली VM धीमी होती है। 8 CPU चुनें। पहली बार
  engine बनने में 3–6 घंटे सामान्य है।
- **"Permission denied" script चलाते समय** — `chmod +x scripts/*.sh` चलाएँ,
  फिर दोबारा कोशिश करें।
- **APK download नहीं हो रही (तरीका B)** — VM बनाते समय "Allow HTTP traffic"
  tick करना भूल गए होंगे। तरीका A (SSH gear → Download file) इस्तेमाल करें।
- **फ़ोन पर install नहीं हो रहा** — "Install unknown apps" allow करना ज़रूरी है
  (भाग 6, step 1)।
- **SSH window बंद हो गई** — कोई नुकसान नहीं। दोबारा SSH खोलें और Command 2
  फिर चलाएँ। काम resume हो जाएगा।

---

## समय और खर्च का अनुमान

| काम | समय |
|---|---|
| VM बनाना | 2 मिनट |
| engine download (38 GB) | 30–90 मिनट (internet पर निर्भर) |
| engine compile | 2–5 घंटे |
| APK package | 20–40 मिनट |
| फ़ोन पर install | 2 मिनट |

खर्च: मुफ़्त trial credit से पूरा कवर हो जाता है। काम ख़त्म होते ही VM delete
कर दें।

---

## ज़रूरी नोट (कानूनी)

Unreal Engine Epic Games की proprietary चीज़ है। इसका इस्तेमाल Epic के
EULA (End User License Agreement) के तहत होता है। यह प्रोजेक्ट आपकी अपनी
game बनाने के लिए है। आप जो game बनाएँ, उसे बेचने के नियम Epic के EULA में
देखें। अगर आप Epic का मुफ़्त account बनाएँ और Unreal को उसी से इस्तेमाल
करें, तो सबसे साफ़ रास्ता रहता है।
