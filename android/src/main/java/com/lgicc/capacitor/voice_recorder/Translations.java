package com.lgicc.capacitor.voice_recorder;

import java.util.Map;

public class Translations {
	public static class TranslationEntry {
		String title;
		String description;
		String decline;
		String goToSettings;

		TranslationEntry(String title, String description, String decline, String goToSettings) {
			this.title = title;
			this.description = description;
			this.decline = decline;
			this.goToSettings = goToSettings;
		}
	}

	private static final String DEFAULT_LANGUAGE = "en";
	private static final Map<String, Translations.TranslationEntry> translations = Map.ofEntries(
			Map.entry(DEFAULT_LANGUAGE, new Translations.TranslationEntry(
					"Microphone Permission Denied",
					"This feature requires access to the microphone. Please enable it in the app settings.",
					"Cancel",
					"Go to Settings"
			)),

			Map.entry("de", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofonzugriff verweigert",
					"Diese Funktion erfordert Zugriff auf das Mikrofon. Bitte aktivieren Sie ihn in den App-Einstellungen.",
					"Abbrechen",
					"Zu den Einstellungen"
			)),

			Map.entry("fr", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permission du microphone refusée",
					"Cette fonctionnalité nécessite l’accès au microphone. Veuillez l’activer dans les paramètres de l’application.",
					"Annuler",
					"Aller aux paramètres"
			)),

			Map.entry("es", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permiso de micrófono denegado",
					"Esta función requiere acceso al micrófono. Por favor, actívelo en la configuración de la aplicación.",
					"Cancelar",
					"Ir a configuración"
			)),

			Map.entry("it", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Autorizzazione microfono negata",
					"Questa funzione richiede l’accesso al microfono. Attivalo nelle impostazioni dell’app.",
					"Annulla",
					"Vai alle impostazioni"
			)),

			Map.entry("pt", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permissão de microfone negada",
					"Este recurso requer acesso ao microfone. Por favor, ative-o nas configurações do aplicativo.",
					"Cancelar",
					"Ir para configurações"
			)),

			Map.entry("ru", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Доступ к микрофону запрещён",
					"Эта функция требует доступ к микрофону. Пожалуйста, включите его в настройках приложения.",
					"Отмена",
					"Перейти в настройки"
			)),

			Map.entry("ja", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"マイクの許可が拒否されました",
					"この機能にはマイクへのアクセスが必要です。アプリの設定で有効にしてください。",
					"キャンセル",
					"設定へ"
			)),

			Map.entry("zh", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"麦克风权限被拒绝",
					"此功能需要访问麦克风。请在应用设置中启用它。",
					"取消",
					"前往设置"
			)),

			Map.entry("ko", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"마이크 권한 거부됨",
					"이 기능은 마이크 접근 권한이 필요합니다. 앱 설정에서 활성화해주세요.",
					"취소",
					"설정으로 이동"
			)),

			Map.entry("ar", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"تم رفض إذن الميكروفون",
					"هذه الميزة تتطلب الوصول إلى الميكروفون. يرجى تمكينه في إعدادات التطبيق.",
					"إلغاء",
					"اذهب إلى الإعدادات"
			)),

			Map.entry("hi", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"माइक्रोफ़ोन अनुमति अस्वीकृत",
					"इस सुविधा के लिए माइक्रोफ़ोन की पहुंच आवश्यक है। कृपया इसे ऐप सेटिंग्स में सक्षम करें।",
					"रद्द करें",
					"सेटिंग्स पर जाएं"
			)),

			Map.entry("pl", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Odmowa dostępu do mikrofonu",
					"Ta funkcja wymaga dostępu do mikrofonu. Proszę włączyć go w ustawieniach aplikacji.",
					"Anuluj",
					"Przejdź do ustawień"
			)),

			Map.entry("nl", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Microfoonmachtiging geweigerd",
					"Deze functie heeft toegang tot de microfoon nodig. Schakel dit in via de app-instellingen.",
					"Annuleren",
					"Ga naar instellingen"
			)),

			Map.entry("sv", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofontillstånd nekades",
					"Denna funktion kräver åtkomst till mikrofonen. Vänligen aktivera det i app-inställningarna.",
					"Avbryt",
					"Gå till inställningar"
			)),

			Map.entry("tr", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofon izni reddedildi",
					"Bu özellik mikrofon erişimi gerektirir. Lütfen uygulama ayarlarından etkinleştirin.",
					"İptal",
					"Ayarlar’a git"
			)),

			Map.entry("da", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofontilladelse nægtet",
					"Denne funktion kræver adgang til mikrofonen. Aktivér det venligst i app-indstillingerne.",
					"Annullér",
					"Gå til indstillinger"
			)),

			Map.entry("no", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofontillatelse avvist",
					"Denne funksjonen krever tilgang til mikrofon. Vennligst aktiver den i appens innstillinger.",
					"Avbryt",
					"Gå til innstillinger"
			)),

			Map.entry("cs", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Přístup k mikrofonu odepřen",
					"Tato funkce vyžaduje přístup k mikrofonu. Povolte ho prosím v nastavení aplikace.",
					"Zrušit",
					"Přejít na nastavení"
			)),

			Map.entry("fi", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofonioikeudet evätty",
					"Tämä ominaisuus tarvitsee pääsyn mikrofonille. Ota se käyttöön sovelluksen asetuksissa.",
					"Peruuta",
					"Siirry asetuksiin"
			)),

			Map.entry("he", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"בשימוש במיקרופון נדחה",
					"תכונה זו דורשת גישה למיקרופון. אנא אפשר אותו בהגדרות האפליקציה.",
					"ביטול",
					"עבור להגדרות"
			)),

			Map.entry("id", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Izin mikrofon ditolak",
					"Fitur ini membutuhkan akses ke mikrofon. Harap aktifkan di pengaturan aplikasi.",
					"Batal",
					"Buka Pengaturan"
			)),

			Map.entry("ms", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Kebenaran mikrofon ditolak",
					"Ciri ini memerlukan akses ke mikrofon. Sila aktifkan dalam tetapan aplikasi.",
					"Batal",
					"Pergi ke Tetapan"
			)),

			Map.entry("th", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"การอนุญาตไมโครโฟนถูกปฏิเสธ",
					"ฟีเจอร์นี้ต้องการการเข้าถึงไมโครโฟน โปรดเปิดในการตั้งค่าแอป",
					"ยกเลิก",
					"ไปที่การตั้งค่า"
			)),

			Map.entry("vi", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Quyền truy cập micro bị từ chối",
					"Tính năng này yêu cầu truy cập microphone. Vui lòng bật trong cài đặt ứng dụng.",
					"Hủy",
					"Đi tới Cài đặt"
			)),

			Map.entry("uk", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Доступ до мікрофона заборонений",
					"Ця функція вимагає доступу до мікрофона. Будь ласка, увімкніть його в налаштуваннях додатка.",
					"Скасувати",
					"Перейти до налаштувань"
			)),

			Map.entry("sr", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Доступ до микрофона одбијен",
					"Ова функција захтева приступ микрофону. Молимо Вас омогућите га у подешавањима апликације.",
					"Откажи",
					"Иди на подешавања"
			)),

			Map.entry("ro", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permisiunea pentru microfon a fost refuzată",
					"Această funcție necesită acces la microfon. Vă rugăm să îl activați în setările aplicației.",
					"Anulare",
					"Mergi la setări"
			)),

			Map.entry("bg", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Достъпът до микрофон е отказан",
					"Тази функция изисква достъп до микрофон. Моля, активирайте го в настройките на приложението.",
					"Отказ",
					"Отидете в настройките"
			)),

			Map.entry("hr", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Pristup mikrofonu odbijen",
					"Ova funkcija zahtijeva pristup mikrofonu. Molimo omogućite ga u postavkama aplikacije.",
					"Otkaži",
					"Idi na postavke"
			)),

			Map.entry("sk", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Prístup k mikrofónu zamietnutý",
					"Táto funkcia vyžaduje prístup k mikrofónu. Prosím, povoľte ho v nastaveniach aplikácie.",
					"Zrušiť",
					"Prejsť do nastavení"
			)),

			Map.entry("mt", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Issaħba tal-mikrofonu miċħud",
					"Din il-funzjoni teħtieġ aċċess għall-mikrofonu. Jekk jogħġbok, iġġibha attiva fit-settings tal-applikazzjoni.",
					"Ikkanċella",
					"Mur għall-settings"
			)),

			Map.entry("bs", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Pristup mikrofonu odbijen",
					"Ova funkcija zahtijeva pristup mikrofonu. Molimo omogućite ga u postavkama aplikacije.",
					"Otkaži",
					"Idi na postavke"
			)),

			Map.entry("lt", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofono prieiga uždrausta",
					"Ši funkcija reikalauja prieigos prie mikrofono. Prašome įjunkite ją programėlės nustatymuose.",
					"Atšaukti",
					"Eiti į nustatymus"
			)),

			Map.entry("lv", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofona piekļuve liegta",
					"Šai funkcijai nepieciešama piekļuve mikrofonam. Lūdzu, iespējot to lietotnes iestatījumos.",
					"Atcelt",
					"Dodieties uz iestatījumiem"
			)),

			Map.entry("et", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofoni luba keeldus",
					"See funktsioon nõuab mikrofonile juurdepääsu. Palun lubage see rakenduse seadetes.",
					"Tühista",
					"Mine seadistustesse"
			)),

			Map.entry("mk", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Пристапот до микрофон е одбиен",
					"Оваа функција бара пристап до микрофон. Ве молиме овозможете го во поставките на апликацијата.",
					"Откажи",
					"Оди во поставки"
			)),

			Map.entry("sq", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Lejimi për mikrofon refuzuar",
					"Kjo veçori kërkon akses në mikrofon. Ju lutemi aktivizoni në cilësimet e aplikacionit.",
					"Anulo",
					"Shko te cilësimet"
			)),

			Map.entry("az", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofon icazəsi rədd edildi",
					"Bu xüsusiyyət mikrofon girişi tələb edir. Zəhmət olmasa, tətbiqin parametrlərində onu aktiv edin.",
					"Ləğv et",
					"Parametrlərə keç"
			)),

			Map.entry("hy", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Միկրոֆոնի թույլատրությունը մերժվեց",
					"Այս ֆունկցիան պահանջում է միկրոֆոնի հասանելիություն: Խնդրում ենք միացնել հավելվածի կարգավորումների մեջ:",
					"Չեղարկել",
					"Գնալ կարգավորումներ"
			)),

			Map.entry("ka", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"მიკროფონის ნებართვა უარყოფილი",
					"ეს ფუნქცია საჭიროებს წვდომას მიკროფონზე. გთხოვთ, ჩართეთ აპლიკაციის პარამეტრებში.",
					"გაუქმება",
					"სეტინგებში გადასვლა"
			)),

			Map.entry("is", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Hljóðnemaheimild neituð",
					"Þessi aðgerð krefst aðgangs að hljóðnema. Vinsamlegast virkjaðu það í stillingum appsins.",
					"Hætta við",
					"Fara í stillingar"
			)),

			Map.entry("eu", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Mikrofono baimenik ukatu",
					"Funtzio honek mikrofonoaren sarbidea behar du. Mesedez, gaitu aplikazioko ezarpenetan.",
					"Utzi",
					"Joan ezarpenetara"
			)),

			Map.entry("gl", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permiso de micrófono denegado",
					"Esta función require acceso ao micrófono. Por favor, actívao na configuración da aplicación.",
					"Cancelar",
					"Ir á configuración"
			)),

			Map.entry("oc", new com.lgicc.capacitor.voice_recorder.Translations.TranslationEntry(
					"Permession de micròfon refusada",
					"Aquesta foncionalitat requerís l’accès al micròfon. Mercés d’activalo dins los paramètres de l’aplicacion.",
					"Anullar",
					"Anar als paramètres"
			))
        );

	public static Translations.TranslationEntry getTranslation(String language) {
		Translations.TranslationEntry translation = translations.get(language);
		return translation != null ? translation : translations.get(DEFAULT_LANGUAGE);
	}
}
