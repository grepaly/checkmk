MONITORING_PLUGINS := monitoring-plugins
MONITORING_PLUGINS_VERS := 2.3.1
MONITORING_PLUGINS_DIR := $(MONITORING_PLUGINS)-$(MONITORING_PLUGINS_VERS)
# Increase this to enforce a recreation of the build cache
MONITORING_PLUGINS_BUILD_ID := 9

MONITORING_PLUGINS_PATCHING := $(BUILD_HELPER_DIR)/$(MONITORING_PLUGINS_DIR)-patching
MONITORING_PLUGINS_BUILD := $(BUILD_HELPER_DIR)/$(MONITORING_PLUGINS_DIR)-build
MONITORING_PLUGINS_INTERMEDIATE_INSTALL := $(BUILD_HELPER_DIR)/$(MONITORING_PLUGINS_DIR)-install-intermediate
MONITORING_PLUGINS_CACHE_PKG_PROCESS := $(BUILD_HELPER_DIR)/$(MONITORING_PLUGINS_DIR)-cache-pkg-process
MONITORING_PLUGINS_INSTALL := $(BUILD_HELPER_DIR)/$(MONITORING_PLUGINS_DIR)-install

MONITORING_PLUGINS_INSTALL_DIR := $(INTERMEDIATE_INSTALL_BASE)/$(MONITORING_PLUGINS_DIR)
MONITORING_PLUGINS_BUILD_DIR := $(PACKAGE_BUILD_DIR)/$(MONITORING_PLUGINS_DIR)
#MONITORING_PLUGINS_WORK_DIR := $(PACKAGE_WORK_DIR)/$(MONITORING_PLUGINS_DIR)

# We're using here only the relative folder for snmp commands:
# the full path will be dynamically calculated in the check_snmp/check_hpjd binary.
# That way we can use cached builds in multiple checkmk versions.
MONITORING_PLUGINS_CONFIGUREOPTS := \
    --prefix="" \
    --libexecdir=/lib/nagios/plugins \
    --with-snmpget-command=/bin/snmpget \
    --with-snmpgetnext-command=/bin/snmpgetnext

$(MONITORING_PLUGINS): $(MONITORING_PLUGINS_BUILD)

$(MONITORING_PLUGINS_BUILD): $(MONITORING_PLUGINS_PATCHING) $(OPENSSL_CACHE_PKG_PROCESS)
	cp $(PACKAGE_DIR)/$(MONITORING_PLUGINS)/cmk_password_store.h $(MONITORING_PLUGINS_BUILD_DIR)/plugins
	cd $(MONITORING_PLUGINS_BUILD_DIR) ; \
	    LD_LIBRARY_PATH="$(PACKAGE_OPENSSL_LD_LIBRARY_PATH)" ; \
	    LDFLAGS="-Wl,-rpath=$(OMD_ROOT)/lib" \
	        ./configure \
	            --with-openssl=$(PACKAGE_OPENSSL_DESTDIR) \
	            $(MONITORING_PLUGINS_CONFIGUREOPTS)
	$(MAKE) -C $(MONITORING_PLUGINS_BUILD_DIR) all
	$(RM) plugins-scripts/check_ifoperstatus plugins-scripts/check_ifstatus
	$(TOUCH) $@

MONITORING_PLUGINS_CACHE_PKG_PATH := $(call cache_pkg_path,$(MONITORING_PLUGINS_DIR),$(MONITORING_PLUGINS_BUILD_ID))

$(MONITORING_PLUGINS_CACHE_PKG_PATH):
	$(call pack_pkg_archive,$@,$(MONITORING_PLUGINS_DIR),$(MONITORING_PLUGINS_BUILD_ID),$(MONITORING_PLUGINS_INTERMEDIATE_INSTALL))

$(MONITORING_PLUGINS_CACHE_PKG_PROCESS): $(MONITORING_PLUGINS_CACHE_PKG_PATH)
	$(call unpack_pkg_archive,$(MONITORING_PLUGINS_CACHE_PKG_PATH),$(MONITORING_PLUGINS_DIR))
	$(call upload_pkg_archive,$(MONITORING_PLUGINS_CACHE_PKG_PATH),$(MONITORING_PLUGINS_DIR),$(MONITORING_PLUGINS_BUILD_ID))
	$(TOUCH) $@

$(MONITORING_PLUGINS_INTERMEDIATE_INSTALL): $(MONITORING_PLUGINS_BUILD)
	$(MAKE) DESTDIR=$(MONITORING_PLUGINS_INSTALL_DIR) -C $(MONITORING_PLUGINS_BUILD_DIR) install
	# FIXME: pack these with SUID root
	install -m 755 $(MONITORING_PLUGINS_BUILD_DIR)/plugins-root/check_icmp $(MONITORING_PLUGINS_INSTALL_DIR)/lib/nagios/plugins
	install -m 755 $(MONITORING_PLUGINS_BUILD_DIR)/plugins-root/check_dhcp $(MONITORING_PLUGINS_INSTALL_DIR)/lib/nagios/plugins
	ln -sf check_icmp $(MONITORING_PLUGINS_INSTALL_DIR)/lib/nagios/plugins/check_host

	# Copy package documentations to have these information in the binary packages
	$(MKDIR) $(MONITORING_PLUGINS_INSTALL_DIR)/share/doc/$(MONITORING_PLUGINS)
	set -e ; for file in ACKNOWLEDGEMENTS AUTHORS CODING COPYING FAQ NEWS README REQUIREMENTS SUPPORT THANKS ; do \
	   install -m 644 $(MONITORING_PLUGINS_BUILD_DIR)/$$file $(MONITORING_PLUGINS_INSTALL_DIR)/share/doc/$(MONITORING_PLUGINS); \
	done
	$(TOUCH) $@

$(MONITORING_PLUGINS_INSTALL): $(MONITORING_PLUGINS_CACHE_PKG_PROCESS)
	$(RSYNC) $(MONITORING_PLUGINS_INSTALL_DIR)/ $(DESTDIR)$(OMD_ROOT)/
	$(TOUCH) $@
