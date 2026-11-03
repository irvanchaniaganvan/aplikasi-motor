const STORAGE_KEY = "rawat-motor-data-v1";

const form = document.querySelector("#motor-form");
const currentInput = document.querySelector("#current-odometer");
const lastOilInput = document.querySelector("#last-oil-odometer");
const intervalInput = document.querySelector("#oil-interval");
const formError = document.querySelector("#form-error");
const reminderValue = document.querySelector("#reminder-value");
const reminderCaption = document.querySelector("#reminder-caption");
const summaryCurrent = document.querySelector("#summary-current");
const summaryNext = document.querySelector("#summary-next");
const recordOilButton = document.querySelector("#record-oil-change");
const actionHint = document.querySelector("#action-hint");
const statusCard = document.querySelector(".status-card");

let motorData = loadMotorData();

function loadMotorData() {
  try {
    const savedData = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? "null");
    if (
      savedData &&
      Number.isFinite(savedData.currentOdometer) &&
      Number.isFinite(savedData.lastOilOdometer) &&
      Number.isFinite(savedData.oilInterval) &&
      savedData.currentOdometer >= savedData.lastOilOdometer &&
      savedData.lastOilOdometer >= 0 &&
      savedData.oilInterval > 0
    ) {
      return savedData;
    }
  } catch {
    // Data yang rusak atau tidak bisa dibaca akan diperlakukan seperti data kosong.
  }

  return null;
}

function saveMotorData() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(motorData));
    return true;
  } catch {
    showError("Data belum tersimpan. Coba buka aplikasi di browser biasa, bukan mode privat.");
    return false;
  }
}

function formatKilometers(value) {
  return `${new Intl.NumberFormat("id-ID").format(value)} km`;
}

function showError(message) {
  formError.textContent = message;
  formError.hidden = false;
}

function clearError() {
  formError.textContent = "";
  formError.hidden = true;
}

function renderMotorData() {
  const hasData = motorData !== null;
  recordOilButton.disabled = !hasData;
  statusCard.classList.remove("is-due");

  if (!hasData) {
    summaryCurrent.textContent = "—";
    summaryNext.textContent = "—";
    reminderValue.textContent = "—";
    reminderCaption.textContent = "Isi data motor untuk melihat jadwal oli.";
    actionHint.textContent = "Tombol aktif setelah data motor disimpan.";
    return;
  }

  currentInput.value = motorData.currentOdometer;
  lastOilInput.value = motorData.lastOilOdometer;
  intervalInput.value = motorData.oilInterval;

  const nextOilOdometer = motorData.lastOilOdometer + motorData.oilInterval;
  const distanceRemaining = nextOilOdometer - motorData.currentOdometer;
  summaryCurrent.textContent = formatKilometers(motorData.currentOdometer);
  summaryNext.textContent = formatKilometers(nextOilOdometer);

  if (distanceRemaining <= 0) {
    statusCard.classList.add("is-due");
    reminderValue.textContent = distanceRemaining === 0
      ? "Sudah waktunya"
      : `Terlambat ${formatKilometers(Math.abs(distanceRemaining))}`;
    reminderCaption.textContent = "Jadwal ganti oli sudah tercapai.";
  } else {
    reminderValue.textContent = `${formatKilometers(distanceRemaining)} lagi`;
    reminderCaption.textContent = "menuju jadwal ganti oli berikutnya";
  }

  actionHint.textContent = `Ganti oli terakhir dicatat di ${formatKilometers(motorData.lastOilOdometer)}.`;
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  clearError();

  const currentOdometer = Number(currentInput.value);
  const lastOilOdometer = Number(lastOilInput.value);
  const oilInterval = Number(intervalInput.value);

  if (![currentOdometer, lastOilOdometer, oilInterval].every(Number.isFinite)) {
    showError("Isi semua angka dengan benar dulu, ya.");
    return;
  }

  if (lastOilOdometer > currentOdometer) {
    showError("Kilometer ganti oli terakhir tidak boleh lebih besar dari kilometer saat ini.");
    return;
  }

  if (oilInterval <= 0) {
    showError("Jarak pengingat harus lebih besar dari 0 km.");
    return;
  }

  motorData = { currentOdometer, lastOilOdometer, oilInterval };
  if (saveMotorData()) renderMotorData();
});

recordOilButton.addEventListener("click", () => {
  if (!motorData) return;

  motorData.lastOilOdometer = motorData.currentOdometer;
  clearError();
  if (saveMotorData()) renderMotorData();
});

renderMotorData();
