//
//	License type: BSD 3-Clause License
//	License copy: https://github.com/Telecominfraproject/wlan-cloud-ucentralgw/blob/master/LICENSE
//
//	Created by Stephane Bourque on 2021-03-04.
//	Arilia Wireless Inc.
//

#ifndef UCENTRAL_USTORAGESERVICE_H
#define UCENTRAL_USTORAGESERVICE_H

#include "Poco/Data/Session.h"
#include "Poco/Data/SessionPool.h"
#include "Poco/Data/SQLite/Connector.h"
#include "Poco/JSON/Object.h"

#include "RESTAPI/RESTAPI_FMSObjects.h"
#include "framework/SubSystemServer.h"

#include "storage/storage_firmwares.h"
#include "storage/storage_history.h"
#include "storage/storage_deviceTypes.h"
#include "storage/storage_deviceInfo.h"

#ifndef SMALL_BUILD
#include "Poco/Data/PostgreSQL/Connector.h"
#include "Poco/Data/MySQL/Connector.h"
#endif

#include "framework/Storage.h"

namespace OpenWifi {

    class Storage : public SubSystemServer {
    public:

        int Create_Tables();
        int Create_Firmwares();
        int Create_History();
        int Create_DeviceTypes();
        int Create_DeviceInfo();

        bool AddFirmware(FMSObjects::Firmware & F);
        bool UpdateFirmware(std::string & UUID, FMSObjects::Firmware & C);
        bool DeleteFirmware(std::string & UUID);
        bool GetFirmware(std::string & UUID, FMSObjects::Firmware & C);
        bool GetFirmwares(uint64_t From, uint64_t HowMany, std::string & Compatible, FMSObjects::FirmwareVec & Firmwares);
        bool BuildFirmwareManifest(Poco::JSON::Object & Manifest, uint64_t & Version);
        bool GetFirmwareByName(std::string & Release, std::string &DeviceType,FMSObjects::Firmware & C );
        bool GetFirmwareByRevision(std::string & Revision, std::string &DeviceType,FMSObjects::Firmware & C );
        bool ComputeFirmwareAge(std::string & DeviceType, std::string & Revision, FMSObjects::FirmwareAgeDetails &AgeDetails);

        bool GetHistory(std::string &SerialNumber,uint64_t From, uint64_t HowMany,FMSObjects::RevisionHistoryEntryVec &History);
        bool AddHistory(FMSObjects::RevisionHistoryEntry &History);

        void PopulateLatestFirmwareCache();
        void RemoveOldFirmware();

        int 	Start() override;
        void 	Stop() override;

        [[nodiscard]] std::string ConvertParams(const std::string &S) const;
        [[nodiscard]] inline std::string ComputeRange(uint64_t From, uint64_t HowMany) {
            if(dbType_==sqlite) {
                return " LIMIT " + std::to_string(From-1) + ", " + std::to_string(HowMany) + " ";
            } else if(dbType_==pgsql) {
                return " LIMIT " + std::to_string(HowMany) + " OFFSET " + std::to_string(From-1) + " ";
            } else if(dbType_==mysql) {
                return " LIMIT " + std::to_string(HowMany) + " OFFSET " + std::to_string(From-1) + " ";
            }
            return " LIMIT " + std::to_string(HowMany) + " OFFSET " + std::to_string(From-1) + " ";
        }

        bool    SetDeviceRevision(std::string &SerialNumber, std::string & Revision, std::string & DeviceType, std::string &EndPoint);

        bool AddHistory( std::string & SerialNumber, std::string &DeviceType, std::string & PreviousRevision, std::string & NewVersion);
        bool DeleteHistory( std::string & SerialNumber, std::string &Id);

        bool GetDevices(uint64_t From, uint64_t HowMany, std::vector<FMSObjects::DeviceConnectionInformation> & Devices);
        bool GetDevice(std::string &SerialNumber, FMSObjects::DeviceConnectionInformation & Device);
        bool SetDeviceDisconnected(std::string &SerialNumber, std::string &EndPoint);

        bool GenerateDeviceReport(FMSObjects::DeviceReport &Report);
        static std::string TrimRevision(const std::string &R);
        static Storage *instance() {
            if (instance_ == nullptr) {
                instance_ = new Storage;
            }
            return instance_;
        }

	  private:
		static Storage      							    *instance_;
		std::unique_ptr<Poco::Data::SessionPool>            Pool_= nullptr;
        DBType   										    dbType_ = sqlite;
        std::unique_ptr<Poco::Data::SQLite::Connector>  	SQLiteConn_= nullptr;
#ifndef SMALL_BUILD
        std::unique_ptr<Poco::Data::PostgreSQL::Connector>  PostgresConn_= nullptr;
        std::unique_ptr<Poco::Data::MySQL::Connector>       MySQLConn_= nullptr;
#endif

        Storage() noexcept:
                SubSystemServer("Storage", "STORAGE-SVR", "storage")
        {
        }

        int 	Setup_SQLite();
        int 	Setup_MySQL();
        int 	Setup_PostgreSQL();

    };

    inline Storage * Storage() { return Storage::instance(); };

}  // namespace

#endif //UCENTRAL_USTORAGESERVICE_H
