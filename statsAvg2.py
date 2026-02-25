import re, csv, json
from datetime import datetime, timedelta
from collections import defaultdict
from pathlib import Path
import matplotlib.pyplot as plt

def name_mapper(x):
    return "Matias" if "Matias" in x else "Girl"

def parse_whatsapp(file_path):
    """Extracts messages from a WhatsApp .txt export."""
    chat_file = Path(file_path).read_text(encoding='utf-8')
    pattern = r"(\d{1,2}/\d{1,2}/\d{2}),\s(\d{2}:\d{2})\s-\s(.*?):\s(.*?)(?=\n\d{1,2}/\d{1,2}/\d{2},|$)"
    matches = re.finditer(pattern, chat_file, re.DOTALL)
    
    data = []
    for match in matches:
        date_str, time_str, sender, content = match.groups()
        dt_obj = datetime.strptime(f"{date_str} {time_str}", "%m/%d/%y %H:%M")
        data.append([dt_obj, name_mapper(sender), content.strip()])
    print(f"Whatsapp msgs: {len(data)}")
    return data

def parse_instagram(file_path):
    """Extracts messages from an Instagram/Messenger .json export."""
    data = []
    path = Path(file_path)
    
    if path.exists():
        ig_chat = json.loads(path.read_text())["messages"]
        for msg in ig_chat:
            dt_obj = datetime.fromtimestamp(msg["timestamp_ms"] / 1000.0)
            raw_content = msg.get("content", "")
            
            # Label attachments to keep word count logic consistent
            content = "ATTACHMENT" if ("sent an attachment" in raw_content.lower() or "share" in msg) else raw_content
            data.append([dt_obj, name_mapper(msg["sender_name"]), content])
    print(f"Instagram msgs: {len(data)}")
    return data

def write_csv(msgs, output_file="data.csv"):
    """Appends messages to the CSV file, adding a header only if the file is new."""
    file_path = Path(output_file)
    file_exists = file_path.exists()

    # Use "a" mode for appending
    with open(output_file, "a", newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f)
        if not file_exists: writer.writerow(["datetime", "sender", "content"])            
        writer.writerows([[d.strftime("%Y-%m-%d %H:%M:%S"), s, c] for d, s, c in msgs])

def read_csv(file_path="data.csv"):
    """Reads processed messages from the CSV to avoid re-parsing raw exports."""
    data = []
    path = Path(file_path)
    if not path.exists():
        print(f"Error: {file_path} not found.")
        return []

    with open(file_path, "r", encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Convert the string back into a datetime object
            dt_obj = datetime.strptime(row["datetime"], "%Y-%m-%d %H:%M:%S")
            data.append([dt_obj, row["sender"], row["content"]])
    
    return data


def plot_avg(msgs, output_img="word_count_avg_plot.png"):
    """Calculates weekly statistics and saves a trend plot."""
    print("plot_avg",len(msgs))
    def get_monday(dt):
        return (dt - timedelta(days=dt.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)

    summary_dict = defaultdict(int)
    for d, s, c in msgs:
        week_start = get_monday(d).strftime("%Y-%m-%d")
        summary_dict[(week_start, s)] += len(str(c).split())

    sorted_weeks = sorted(list({w for w, s in summary_dict}))
    sorted_senders = sorted(list({s for w, s in summary_dict}))
    all_dates = [m[0] for m in msgs]
    first_date = min(all_dates)
    last_date = max(all_dates)

    plt.figure(figsize=(12, 6))
    plt.style.use('seaborn-v0_8-muted')

    for sender_name in sorted_senders:
        daily_averages = []
        for w_str in sorted_weeks:
            current_week_start = datetime.strptime(w_str, "%Y-%m-%d")
            current_week_end = current_week_start + timedelta(days=7)
            
            # Normalize for partial weeks at the start/end of data
            eff_start = max(current_week_start, first_date)
            eff_end = min(current_week_end, last_date)
            
            delta_days = (eff_end - eff_start).total_seconds() / 86400.0
            days_in_week = max(min(delta_days, 7.0), 1.0)
            
            total_words = summary_dict.get((w_str, sender_name), 0)
            daily_averages.append(total_words / days_in_week)

        plt.plot(sorted_weeks, daily_averages, marker='o', markersize=4, label=sender_name)

    plt.title('Daily Average Word Count (Calculated Weekly)')
    plt.ylabel('Avg Words per Day')
    plt.xlabel('Week Starting')
    plt.xticks(rotation=45)
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_img)

if __name__ == "__main__":
    all_msgs = []
    
    # 1. Parse WhatsApp
    wa_files = list(Path().glob("WhatsApp Chat *.txt"))
    if wa_files:
        all_msgs.extend(parse_whatsapp(wa_files[0]))

    # 2. Parse Instagram
    ig_file = "sarita_1793709402021878/message_1.json"
    all_msgs.extend(parse_instagram(ig_file))

    if not all_msgs:
        print("No messages found. Check your file paths!")

    # 3. Sort & Process
    all_msgs.sort(key=lambda x: x[0])
    write_csv(all_msgs)
    plot_avg(all_msgs)
    
    print(f"Done! {len(all_msgs)} messages processed.")

