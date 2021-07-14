//
// Created by stephane bourque on 2021-07-13.
//

#ifndef UCENTRALFMS_LATESTFIRMWARECACHE_H
#define UCENTRALFMS_LATESTFIRMWARECACHE_H

#include "Poco/JSON/Object.h"
#include "Poco/Net/HTTPServerRequest.h"
#include "Poco/Net/HTTPServerResponse.h"
#include "Poco/JWT/Signer.h"
#include "Poco/SHA2Engine.h"
#include "RESTAPI_SecurityObjects.h"
#include "SubSystemServer.h"

namespace uCentral {

    struct LatestFirmwareCacheEntry {
        std::string     Id;
        uint64_t        TimeStamp=0;
        std::string     Revision;
    };
    typedef std::map<std::string, LatestFirmwareCacheEntry> FirmwareCache;

    class LatestFirmwareCache : public SubSystemServer {
    public:
        static LatestFirmwareCache *instance() {
            if (instance_ == nullptr) {
                instance_ = new LatestFirmwareCache;
            }
            return instance_;
        }

        int Start() override;
        void Stop() override;
        void AddToCache(const std::string & DeviceType, const std::string & Revision, const std::string &Id, uint64_t TimeStamp);
        void AddRevision(const std::string &Revision);
        bool FindLatestFirmware(const std::string &DeviceType, LatestFirmwareCacheEntry &Entry );
        void DumpCache();
        inline Types::StringSet GetRevisions() { SubMutexGuard G(Mutex_); return RevisionSet_; };

    private:
        static LatestFirmwareCache 	*instance_;
        FirmwareCache               FirmwareCache_;
        Types::StringSet            RevisionSet_;
        explicit LatestFirmwareCache() noexcept:
                SubSystemServer("FirmwareCache", "FIRMWARE-CACHE", "FirmwareCache")
        {
        }
    };

    inline LatestFirmwareCache * LatestFirmwareCache() { return LatestFirmwareCache::instance(); }
}


#endif //UCENTRALFMS_LATESTFIRMWARECACHE_H
