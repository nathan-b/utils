#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>
#include <list>
#include <thread>
#include <chrono>

#include <cstdint>
#include <unistd.h>
#include <time.h>

using namespace std;

struct stat_vals
{
	enum stat_label
	{
		USER,
		NICE,
		SYSTEM,
		IDLE,
		IOWAIT,
		IRQ,
		SOFTIRQ,
		STEAL,
		MAX
	};

	string label;
	uint64_t vals[stat_label::MAX];

	const string& get_label(int idx)
	{
		static string labels[stat_label::MAX] = 
		{
			"user",
			"nice",
			"system",
			"idle",
			"iowait",
			"irq",
			"softirq",
			"steal"
		};
	
		return labels[idx];
	}

	uint64_t get_total()
	{
		uint64_t ret = 0;
		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ret += vals[i];
		}

		return ret;
	}

	stat_vals diff(const stat_vals& baseline)
	{
		stat_vals ret;
		ret.label = label + ":delta";
		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ret.vals[i] = vals[i] - baseline.vals[i];
		}

		return ret;
	}

	string print()
	{
		stringstream ss;

		ss << label << " ";

		ss << "total: " << get_total() << "  ";

		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ss << get_label(i) << ": " << vals[i] << "  ";
		}

		return ss.str();
	}

	friend istream& operator>>(istream& in, stat_vals& val);
};

istream& operator>>(istream& in, stat_vals& val)
{
	string line;

	getline(in, line);
	stringstream ss(line);

	ss >> val.label >> ws;

	for(int i = 0; i < stat_vals::stat_label::MAX; ++i)
	{
		ss >> val.vals[i] >> ws;
	}

	return in;
}

list<stat_vals> read_proc_stat()
{
	stat_vals row;
	list<stat_vals> ret;

	ifstream instr("/proc/stat");

	do 
	{
		instr >> row;
		if(row.label.rfind("cpu") == 0) 
		{
			ret.push_back(row);
		}
		else
		{
			break;
		}
	} while(instr);

	return ret;
}

int main(int argc, char** argv)
{
	int nvals = 33;
	int vals[512] = {};
	auto statlist = read_proc_stat();
	auto last_read_ts = std::chrono::steady_clock::now();
	nvals = statlist.size();
	auto last = statlist;
	int totals[512] = {};
	int samples = 0;

	while(true)
	{
		this_thread::sleep_for(chrono::seconds(1));
		statlist = read_proc_stat();
		auto new_last_read_ts = std::chrono::steady_clock::now();
		chrono::milliseconds diff = chrono::duration_cast<chrono::milliseconds>(new_last_read_ts - last_read_ts);
		int expected_jiffies = diff.count() * ((double)sysconf(_SC_CLK_TCK) / 1000.0);
		last_read_ts = new_last_read_ts;

		nvals = statlist.size();
		int i = 0;
		int smallest = 100, sidx;
		int largest = 0, lidx;
		for (auto& cpu : statlist)
		{
			for (auto& oldcpu : last)
			{
				if (cpu.label == oldcpu.label)
				{
					int v = cpu.get_total() - oldcpu.get_total();
					if (v > largest && i > 0)
					{
						largest = v;
						lidx = i;
					}
					if (v < smallest)
					{
						smallest = v;
						sidx = i;
					}
					totals[i] += v;
					vals[i++] = v;
					break;
				}
			}
		}
		
		for (int j = 0; j < nvals; ++j)
		{
			cout << setw(2) << j << ": " << setw(3) << vals[j] << "  ";
		}
		cout << "Largest: cpu" << lidx << " = " << largest 
			 << "  Smallest: cpu" << sidx << " = " << smallest 
			 << "   Expected: " << expected_jiffies << std::endl;

		last = statlist;
		
		// Output averages
		if (++samples % 10 == 0)
		{
			cout << "Averages: ";

			for (int j = 0; j < nvals; ++j)
			{
				cout << setw(2) << j << ": " << setw(3) << (totals[j] / samples) << "  ";
			}
			cout << std::endl;
		}
	}

	return 0;
}

