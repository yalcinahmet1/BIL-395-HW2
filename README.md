# BIL-395-HW2


Çok Dilli Hesap Makinesi Projesi
Bu proje, beş farklı programlama dilinde (Perl, Ada, Scheme, Prolog ve Rust) geliştirilmiş basit hesap makinesi uygulamalarını içermektedir. Her bir uygulama, aynı temel işlevleri farklı programlama paradigmaları kullanarak gerçekleştirmektedir.

Genel Özellikler
Tüm hesap makinesi uygulamaları aşağıdaki ortak özelliklere sahiptir:

Temel Aritmetik İşlemler: Toplama (+), çıkarma (-), çarpma (*), bölme (/)
Parantezli İfadeler: Karmaşık ifadelerde parantez kullanımı desteği
Negatif Sayılar: Negatif değerleri doğru şekilde işleme
Ondalık Sayılar: Ondalık sayıları destekleme
Kapsamlı Hata İşleme: Çeşitli hata durumlarını ele alma
Uygulama Detayları
Her bir uygulama, üç ana bileşenden oluşmaktadır:

Lexer (Sözcük Çözümleyici): Girdi metnini tokenlara ayırır
Parser (Ayrıştırıcı): Tokenları alır ve bir sözdizimi ağacı oluşturur
Interpreter (Yorumlayıcı): Sözdizimi ağacını değerlendirir ve sonucu hesaplar
Diller ve Paradigmalar
1. Perl (Prosedürel/Betik Programlama)
Klasör: calculator_perl

Perl uygulaması, nesne yönelimli bir yaklaşımla geliştirilmiştir. Perl'in esnek sözdizimi ve güçlü metin işleme özellikleri, lexer ve parser uygulamalarını kolaylaştırmıştır.

Özellikler:

Nesne yönelimli tasarım
Düzenli ifadeler kullanarak token ayrıştırma
Kapsamlı hata mesajları
Çalıştırma:

bash
CopyInsert in Terminal
perl calculator_perl/calculator.pl
2. Ada (Güçlü Tip Kontrolü Olan Yapısal Programlama)
Klasör: calculator_ada

Ada uygulaması, güçlü tip kontrolü ve istisna işleme mekanizmaları ile yapısal programlama paradigmasını kullanmaktadır. Ada'nın güvenli ve sağlam kod geliştirme özellikleri, hesap makinesinin güvenilir bir şekilde çalışmasını sağlamaktadır.

Özellikler:

Güçlü tip kontrolü
Kapsamlı istisna işleme
Modüler yapı
Çalıştırma: Ada kodunu online bir derleyicide (OnlineGDB, Ideone veya Replit) çalıştırabilirsiniz veya yerel olarak GNAT derleyicisi ile derleyebilirsiniz:

bash
CopyInsert
gnatmake calculator_ada/calculator_fixed.adb
./calculator_fixed
3. Scheme (Fonksiyonel Programlama)
Klasör: calculator_scheme

Scheme uygulaması, fonksiyonel programlama paradigmasını kullanarak geliştirilmiştir. Scheme'in sade sözdizimi ve fonksiyonel yaklaşımı, özellikle rekürsif ayrıştırma işlemlerinde etkili bir çözüm sunmaktadır.

Özellikler:

Fonksiyonel programlama yaklaşımı
Rekürsif ayrıştırma
Sade ve anlaşılır kod yapısı
Çalıştırma:

bash
CopyInsert in Terminal
racket calculator_scheme/calculator_simple.scm
4. Prolog (Mantıksal Programlama)
Klasör: calculator_prolog

Prolog uygulaması, mantıksal programlama paradigmasını kullanarak geliştirilmiştir. Prolog'un geri izleme (backtracking) özelliği ve DCG (Definite Clause Grammar) yapısı, ayrıştırma işlemlerini daha kısa ve öz bir şekilde gerçekleştirmeyi sağlamaktadır.

Özellikler:

Mantıksal programlama yaklaşımı
DCG kullanarak token ayrıştırma
Geri izleme özelliği ile etkili ayrıştırma
Çalıştırma:

bash
CopyInsert in Terminal
swipl -s calculator_prolog/calculator.pl
5. Rust (Güvenli Sistem Programlama)
Klasör: calculator_rust

Rust uygulaması, modern ve güvenli bir sistem programlama dili kullanarak geliştirilmiştir. Rust'un sahiplik (ownership) modeli ve hata işleme mekanizmaları, güvenli ve verimli bir hesap makinesi uygulaması oluşturmayı sağlamaktadır.

Özellikler:

Güvenli bellek yönetimi
Result ve Option türleri ile etkili hata işleme
Yüksek performans
Çalıştırma:

bash
CopyInsert
cd calculator_rust
cargo run
Karşılaştırma
Bu proje, farklı programlama paradigmalarının aynı problemi nasıl çözdüğünü göstermektedir:

Perl: Esnek ve hızlı geliştirme, ancak büyük projelerde bakımı zor olabilir
Ada: Güvenli ve sağlam, ancak daha fazla kod gerektirir
Scheme: Sade ve elegant, ancak performans açısından diğer dillere göre daha yavaş olabilir
Prolog: Ayrıştırma işlemleri için çok uygun, ancak genel amaçlı programlama için daha az esnek
Rust: Güvenli ve yüksek performanslı, ancak öğrenme eğrisi dik
