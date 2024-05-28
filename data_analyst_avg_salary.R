#Ayşe Mustafaoğlu Uysal 
#7 Mayıs 2024

#Veri setinin yüklenmesi
data_final <- read.csv("https://raw.githubusercontent.com/aysemuu/data-analyst-avg-salary/main/DataAnalyst.csv", na.strings = c("", "NA"), stringsAsFactors =FALSE)


#Veri setinin ilk bir kaç satırının kontrol edilmesi
head(data_final)

#Veri setinin özetlenmesi
summary(data_final)

# 1.VERİ SETİNİN ANALİZE HAZIRLANMASI

# Veri setindeki tüm sütunları kontrol edip -1 değerlerini NA ile değiştirmek
data_final[data_final == -1] <- NA

#Eksik verilerin kontrol edilmesi
colSums(is.na(data_final))

# Eksik verilerin oranını hesaplamak
colSums(is.na(data_final)) / nrow(data_final)

# Ortalama ile doldurma (sadece sayısal sütunlar için)
numeric_cols <- sapply(data_final, is.numeric)
data_final[numeric_cols] <- lapply(data_final[numeric_cols], function(x) {
  x[is.na(x)] <- mean(x, na.rm = TRUE)
  x
})

#Eksik verilerin kontrol edilmesi
colSums(is.na(data_final))

# Eksik verilerin oranını hesaplamak
colSums(is.na(data_final)) / nrow(data_final)

# Salary Estimate için ortalama ile doldurma
mean_salary <- mean(data_final$Salary.Estimate, na.rm = TRUE)
data_final$Salary.Estimate[is.na(data_final$Salary.Estimate)] <- mean_salary

# Salary Estimate sütununun ilk birkaç değerin kontrolü
head(data_final$Salary.Estimate)


# Salary Estimate sütununda hangi benzersiz değerlerin bulunduğunun kontrol edelmesi
unique(data_final$Salary.Estimate)

# "Glassdoor est." metnini ve parantezlerinin temizlenmesi
data_final$Salary.Estimate <- gsub("\\(Glassdoor est.\\)", "", data_final$Salary.Estimate)
 data_final$Salary.Estimate <- gsub("[()]", "", data_final$Salary.Estimate)

# $, K ve boşluk karakterlerinin temizlenmesi
 data_final$Salary.Estimate <- gsub("[$,K ]", "", data_final$Salary.Estimate)

# Maaş aralıklarının ortalamalarını alarak yeni bir sütun oluşturulması
salary_split <- strsplit(data_final$Salary.Estimate, "-")
data_final$avg_salary <- sapply(salary_split, function(x) {
  if(length(x) > 1) mean(as.numeric(x))
  else as.numeric(x)
})

# Dönüşüm sonrası sütunun kontrol edilmesi
head(data_final$avg_salary)

# Eksik veya hatalı değerlerin kontrol edilmesi
sum(is.na(data_final$avg_salary))

# Ortalama ile eksik verilerin doldurulması
mean_salary <- mean(data_final$avg_salary, na.rm = TRUE)
data_final$avg_salary[is.na(data_final$avg_salary)] <- mean_salary

# Mod ile eksik verilerin doldurulması
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

data_final$Size[is.na(data_final$Size)] <- Mode(data_final$Size)
data_final$Type.of.ownership[is.na(data_final$Type.of.ownership)] <- Mode(data_final$Type.of.ownership)

# Çok yüksek eksiklik oranına sahip sütunların çıkarılması
data_final$Competitors <- NULL
data_final$Easy.Apply <- NULL

colSums(is.na(data_final))

# 'X' sütununun veri setinden çıkarılması
data_final$X <- NULL

# Veri setinin güncellenmiş sütun isimlerinin kontrol edilmesi
names(data_final)

# Eksik veri oranları
colSums(is.na(data_final)) / nrow(data_final)

# Kategorik değişkenlerdeki benzersiz değerler
sapply(data_final, function(x) length(unique(x)))

# 2. VERİ SETİNİN GÖRSELLEŞTİRİLMESİ

#Kernel Yoğunluk Grafiği

library(ggplot2)
library(scales)  # Sayıları formatlamak için scales kütüphanesini yükler

# Ortalama Maaş Dağılımı için Kernel Yoğunluk Grafiği
ggplot(data_final, aes(x = avg_salary)) +
  geom_density(fill = "#377eb8", color = "black", alpha = 0.7) +  # Daha iyi görsel sunum için mavi bir ton kullanın, şeffaflık ile
  scale_x_continuous(breaks = pretty_breaks(n = 10), labels = comma) +  # x ekseninde düzenli aralıklar ve formatlanmış sayılar
  scale_y_continuous(breaks = pretty_breaks(n = 10), labels = comma) +  # y ekseninde düzenli aralıklar
  labs(title = "Ortalama Maaş Yoğunluk Grafiği",
       #subtitle = "Veri Setindeki Maaşların Yoğunluk Dağılımı",
       x = "Ortalama Maaş (bin $)",
       y = "Yoğunluk",
       caption = "Veri kaynağı: Kaggle") +
  theme_minimal() +  # Daha temiz bir görünüm için minimal tema 
  theme(plot.title = element_text(face = "bold", size = 16),  # Başlığın boyutu ve stili
        #plot.subtitle = element_text(face = "italic"),
        axis.title = element_text(size = 14))  # Eksen başlıklarının boyutu


#Balon Grafiği

library(dplyr)
library(ggplot2)
library(scales)  # Sayıları formatlamak için scales paketi

# Geçerli verileri filtrele (Sektör bilgisi eksik olmayanlar)
valid_data <- data_final %>%
  filter(!is.na(Sector))

# Sektöre göre gruplandır ve özetle
sector_job_counts <- valid_data %>%
  group_by(Sector) %>%
  summarise(Count = n(),  # Her sektör için satır sayısını sayma
            AvgSalary = mean(avg_salary, na.rm = TRUE))  # Her sektör için ortalama maaşı hesaplama

# Ortalama Maaş ve Sektör üzerine Balon Grafiği
bubble_chart <- ggplot(sector_job_counts, aes(x = AvgSalary, y = Sector, size = Count)) +
  geom_point(alpha = 0.6, color = "#377eb8") +  # Balonları mavi yap ve şeffaflık ekle
  scale_size(range = c(2, 10)) +  # Görünürlük için boyut ölçeğini ayarla
  scale_x_continuous(labels = dollar_format(prefix = "$", suffix = "K", scale = 1)) +  # x ekseni etiketlerini dolar olarak formatla
  labs(title = "Ortalama Maaşa göre Sektörel Dağılım",
       x = "Ortalama Maaş",
       y = "Sektör",
       size = "Sektör Sayısı",
       caption = "Veri kaynağı: Kaggle") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 16),  # Başlığı kalın yap
        plot.caption = element_text(size = 12),  # Açıklama stilini ayarla
        legend.title = element_text(face = "bold"),  # Lejant başlığını kalın yap
        axis.title = element_text(size = 14))  # Eksen başlıklarının boyutu

# Balon grafiğini yazdır
print(bubble_chart)


#Sankey Diyagram


library(dplyr)
library(networkD3)

# Veri setinden en yüksek ortalama maaşa sahip ilk 3 sektörü seçme
top_sectors_data <- data_final %>%
  group_by(Sector) %>%
  summarise(avg_salary = mean(avg_salary, na.rm = TRUE), .groups = 'drop') %>%
  top_n(3, avg_salary) %>%
  arrange(desc(avg_salary))

# Sektör ve lokasyon arasında Sankey diyagramı için veri hazırlığı
sankey_data <- data_final %>%
  filter(Sector %in% top_sectors_data$Sector) %>%
  group_by(Sector, Location) %>%
  summarise(total_salary = sum(avg_salary), .groups = 'drop')

# Nodes ve links verilerini hazırlama
nodes <- data.frame(name=c(as.character(sankey_data$Sector), as.character(sankey_data$Location)))
nodes <- unique(nodes)
links <- data.frame(
  source = match(sankey_data$Sector, nodes$name)-1,
  target = match(sankey_data$Location, nodes$name)-1,
  value = sankey_data$total_salary
)

# Sankey diyagramını oluşturma
sankey <- sankeyNetwork(Links = links, Nodes = nodes, Source = "source", Target = "target", Value = "value", NodeID = "name", units = "$") 

# Kalın başlık ve kaynak bilgisi ekleyerek Sankey diyagramını oluşturma
sankey <- htmlwidgets::onRender(
  sankey,
  '
  function(el, x) {
    // Kalın bir başlık ekleyin
    var title = d3.select(el).insert("div", ":first-child")
      .style("font", "bold 19px sans-serif")
      .style("margin", "5px 0 5px 0")
      .text("Ortalama Maaşa Göre İlk 3 Sektörün Lokasyon Dağılımı");

    // Bir açıklama/kaynak ekleyin
    d3.select(el).append("div")
      .style("font", "italic 12px sans-serif")
      .style("margin", "0 0 5px 0")
      .text("Veri kaynağı: Kaggle");
  }
  '
)

# Sankey diyagramını yazdır 
print(sankey)




#Tableu için gereken datayı hazırlamak ve kaydetmek
# Calculate average salary and count by sector
data_summary <- data_final %>%
  group_by(Location) %>%
  summarise(Count = n(),
            AvgSalary = mean(avg_salary, na.rm = TRUE)) %>%
  arrange(desc(Count)) %>%
  mutate(Location = factor(Location, levels = Location))
write.csv(data_summary, "path/tableau_map.csv") #path için kendi bilgisayırınızda kaydedeceğiniz dosya uzantısını ekleyiniz




